import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

/// Android-only [SpeechOutputPort] using an installed local Spanish voice.
///
/// Never selects a network-required voice or cloud TTS. Completions come from
/// platform utterance callbacks — never text-length or fixed-timer estimates.
/// Audio is ephemeral platform output only (no files, cache or logging).
final class AndroidLocalSpeechOutput implements SpeechOutputPort {
  AndroidLocalSpeechOutput({MethodChannel? channel, bool? isAndroidPlatform})
    : _channel = channel ?? const MethodChannel(_channelName),
      _isAndroid = isAndroidPlatform ?? Platform.isAndroid;

  static const _channelName = 'com.ejemplo.memora.user/local_speech_output';

  final MethodChannel _channel;
  final bool _isAndroid;
  var _speaking = false;

  /// Whether the current host can use the native Android adapter.
  static bool get isSupportedPlatform => Platform.isAndroid;

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<SpeechOutputAvailability> checkAvailability() async {
    if (!_isAndroid) {
      return SpeechOutputAvailability.unavailable;
    }
    try {
      final raw = await _channel.invokeMethod<String>('checkAvailability');
      return switch (raw) {
        'availableOnDevice' => SpeechOutputAvailability.availableOnDevice,
        'networkOnlyVoices' => SpeechOutputAvailability.networkOnlyVoices,
        _ => SpeechOutputAvailability.unavailable,
      };
    } on PlatformException {
      return SpeechOutputAvailability.unavailable;
    }
  }

  @override
  Future<SpeechSpeakOutcome> speak(
    String text, {
    double speechRate = SpeechOutputPort.defaultSpeechRate,
  }) async {
    if (!_isAndroid) {
      return const SpeechSpeakUnavailable();
    }
    final availability = await checkAvailability();
    if (availability != SpeechOutputAvailability.availableOnDevice) {
      return SpeechSpeakUnavailable(availability: availability);
    }

    if (_speaking) {
      await stop();
    }

    _speaking = true;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'speak',
        <String, Object?>{
          'text': text,
          'speechRate': speechRate,
          // Hard contract: refuse network-required voices on the platform side.
          'localOnly': true,
        },
      );
      return _parseSpeakOutcome(raw);
    } on PlatformException catch (error) {
      return SpeechSpeakError(error.code);
    } finally {
      _speaking = false;
    }
  }

  @override
  Future<void> stop() async {
    _speaking = false;
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Best-effort.
    }
  }

  @override
  Future<void> release() async {
    _speaking = false;
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('release');
    } on PlatformException {
      // Idempotent best-effort.
    }
  }

  SpeechSpeakOutcome _parseSpeakOutcome(Map<Object?, Object?>? raw) {
    if (raw == null) {
      return const SpeechSpeakError('null_result');
    }
    final kind = raw['kind'] as String?;
    switch (kind) {
      case 'completed':
        return const SpeechSpeakCompleted();
      case 'cancelled':
        return const SpeechSpeakCancelled();
      case 'unavailable':
        final availability = switch (raw['availability'] as String?) {
          'networkOnlyVoices' => SpeechOutputAvailability.networkOnlyVoices,
          _ => SpeechOutputAvailability.unavailable,
        };
        return SpeechSpeakUnavailable(availability: availability);
      case 'error':
        return SpeechSpeakError(raw['code'] as String?);
      default:
        return SpeechSpeakError(kind ?? 'unknown');
    }
  }
}
