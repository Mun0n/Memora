import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

/// Android-only [SpeechRecognizerPort] using on-device recognition exclusively.
///
/// Never falls back to a network recognizer. Android app runs use this adapter
/// by default; tests can still inject [FakeSpeechRecognizer].
final class AndroidOnDeviceSpeechRecognizer implements SpeechRecognizerPort {
  AndroidOnDeviceSpeechRecognizer({
    MethodChannel? channel,
    bool? isAndroidPlatform,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _isAndroid = isAndroidPlatform ?? Platform.isAndroid;

  static const _channelName = 'com.ejemplo.memora.user/on_device_speech';

  final MethodChannel _channel;
  final bool _isAndroid;
  var _listening = false;

  /// Whether the current host can use the native Android adapter.
  static bool get isSupportedPlatform => Platform.isAndroid;

  @override
  bool get isListening => _listening;

  @override
  Future<SpeechRecognizerAvailability> checkAvailability() async {
    if (!_isAndroid) {
      return SpeechRecognizerAvailability.unavailable;
    }
    try {
      final raw = await _channel.invokeMethod<String>('checkAvailability');
      return switch (raw) {
        'availableOnDevice' => SpeechRecognizerAvailability.availableOnDevice,
        'languagePackMissing' =>
          SpeechRecognizerAvailability.languagePackMissing,
        _ => SpeechRecognizerAvailability.unavailable,
      };
    } on PlatformException {
      return SpeechRecognizerAvailability.unavailable;
    }
  }

  @override
  Future<SpeechPermissionStatus> permissionStatus() async {
    if (!_isAndroid) {
      return SpeechPermissionStatus.denied;
    }
    try {
      final raw = await _channel.invokeMethod<String>('permissionStatus');
      return _parsePermission(raw);
    } on PlatformException {
      return SpeechPermissionStatus.denied;
    }
  }

  @override
  Future<SpeechPermissionStatus> requestPermission() async {
    if (!_isAndroid) {
      return SpeechPermissionStatus.denied;
    }
    try {
      final raw = await _channel.invokeMethod<String>('requestPermission');
      return _parsePermission(raw);
    } on PlatformException {
      return SpeechPermissionStatus.denied;
    }
  }

  @override
  Future<SpeechListenOutcome> listen({Duration? timeout}) async {
    if (!_isAndroid) {
      return const SpeechUnavailableOutcome();
    }
    final availability = await checkAvailability();
    if (availability != SpeechRecognizerAvailability.availableOnDevice) {
      return SpeechUnavailableOutcome(availability: availability);
    }
    final permission = await permissionStatus();
    if (permission != SpeechPermissionStatus.granted) {
      return SpeechPermissionDeniedOutcome(
        permanent: permission == SpeechPermissionStatus.permanentlyDenied,
      );
    }

    _listening = true;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'listen',
        <String, Object?>{
          'timeoutMs': (timeout ?? const Duration(seconds: 8)).inMilliseconds,
          // Hard contract: refuse network fallback on the platform side.
          'onDeviceOnly': true,
        },
      );
      return _parseListenOutcome(raw);
    } on PlatformException catch (error) {
      return SpeechListenError(error.code);
    } finally {
      _listening = false;
    }
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('cancel');
    } on PlatformException {
      // Best-effort release path.
    }
  }

  @override
  Future<void> release() async {
    _listening = false;
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('release');
    } on PlatformException {
      // Idempotent best-effort.
    }
  }

  SpeechPermissionStatus _parsePermission(String? raw) {
    return switch (raw) {
      'granted' => SpeechPermissionStatus.granted,
      'denied' => SpeechPermissionStatus.denied,
      'permanentlyDenied' => SpeechPermissionStatus.permanentlyDenied,
      _ => SpeechPermissionStatus.notDetermined,
    };
  }

  SpeechListenOutcome _parseListenOutcome(Map<Object?, Object?>? raw) {
    if (raw == null) {
      return const SpeechListenError('null_result');
    }
    final kind = raw['kind'] as String?;
    switch (kind) {
      case 'recognized':
        final text = (raw['text'] as String?)?.trim() ?? '';
        if (text.isEmpty) {
          return const SpeechSilence();
        }
        // Ephemeral — caller must not persist/log/sync.
        return SpeechRecognized(text);
      case 'silence':
        return const SpeechSilence();
      case 'timeout':
        return const SpeechTimeout();
      case 'cancelled':
        return const SpeechCancelled();
      case 'permissionDenied':
        return SpeechPermissionDeniedOutcome(
          permanent: raw['permanent'] == true,
        );
      case 'unavailable':
        final availability = switch (raw['availability'] as String?) {
          'languagePackMissing' =>
            SpeechRecognizerAvailability.languagePackMissing,
          _ => SpeechRecognizerAvailability.unavailable,
        };
        return SpeechUnavailableOutcome(availability: availability);
      case 'error':
        return SpeechListenError(raw['code'] as String?);
      default:
        return SpeechListenError(kind ?? 'unknown');
    }
  }
}
