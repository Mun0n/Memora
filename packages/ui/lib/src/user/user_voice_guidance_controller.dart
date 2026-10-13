import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../l10n/memora_copy.dart';
import 'user_home_destination.dart';

/// Visible phases of the tap-gated voice guidance flow.
enum VoiceGuidancePhase {
  /// Home idle — no overlay; nothing listens.
  idle,

  /// Plain-language mic explanation before the first permission request.
  permissionExplain,

  /// The Android permission sheet is being opened.
  permissionRequesting,

  /// Short on-device listen session with Cancelar.
  listening,

  /// Classifying ephemeral text (not colour/sound alone).
  processing,

  /// Exactly one destination suggestion; navigate only after confirm.
  suggestion,

  /// Fixed non-destination outcomes with retry / manual / cancel.
  unclear,
  nothingPrepared,
  safetyLimitation,
  unavailable,
  permissionDenied,
  silence,
  timeout,
  error,
}

/// Orchestrates Slice 9 voice guidance over [SpeechRecognizerPort] + policy.
///
/// Never persists, logs, syncs or sends audio/transcript/intent/history. The
/// recognized phrase is kept only in memory while the result panel is visible.
final class UserVoiceGuidanceController extends ChangeNotifier {
  UserVoiceGuidanceController({
    required SpeechRecognizerPort recognizer,
    required VoiceContentSnapshot Function() contentSnapshot,
    this.listenTimeout = const Duration(seconds: 8),
  }) : _recognizer = recognizer,
       _contentSnapshot = contentSnapshot;

  final SpeechRecognizerPort _recognizer;
  final VoiceContentSnapshot Function() _contentSnapshot;
  final Duration listenTimeout;

  VoiceGuidancePhase phase = VoiceGuidancePhase.idle;
  VoiceGuidanceDecision? decision;
  String? message;
  String? recognizedText;
  HomeGuidanceDestination? suggestedDestination;
  var _sessionActive = false;

  bool get isActive => phase != VoiceGuidancePhase.idle;

  /// True while an on-device listen session may hold the microphone.
  bool get isListeningPhase =>
      phase == VoiceGuidancePhase.listening ||
      phase == VoiceGuidancePhase.processing;

  UserHomeDestination? get navigationTarget {
    final dest = suggestedDestination;
    if (dest == null) {
      return null;
    }
    return switch (dest) {
      HomeGuidanceDestination.miDia => UserHomeDestination.miDia,
      HomeGuidanceDestination.pasatiempos => UserHomeDestination.pasatiempos,
      HomeGuidanceDestination.quieroHablar => UserHomeDestination.quieroHablar,
      HomeGuidanceDestination.recuerdos => UserHomeDestination.recuerdos,
    };
  }

  /// Entry from an explicit `Ayúdame` tap. Does not listen until checks pass.
  Future<void> startFromExplicitTap() async {
    if (_sessionActive) {
      return;
    }
    _sessionActive = true;
    decision = null;
    suggestedDestination = null;
    message = null;
    recognizedText = null;

    final availability = await _recognizer.checkAvailability();
    if (!_sessionActive) {
      return;
    }
    if (availability != SpeechRecognizerAvailability.availableOnDevice) {
      _showTerminal(
        VoiceGuidancePhase.unavailable,
        MemoraCopy.voiceRecognizerUnavailable,
      );
      await _recognizer.release();
      return;
    }

    final permission = await _recognizer.permissionStatus();
    if (!_sessionActive) {
      return;
    }
    if (permission == SpeechPermissionStatus.notDetermined) {
      phase = VoiceGuidancePhase.permissionExplain;
      message = MemoraCopy.voicePermissionExplain;
      notifyListeners();
      return;
    }
    if (permission == SpeechPermissionStatus.denied ||
        permission == SpeechPermissionStatus.permanentlyDenied) {
      _showTerminal(
        VoiceGuidancePhase.permissionDenied,
        MemoraCopy.voicePermissionDenied,
      );
      await _recognizer.release();
      return;
    }

    await _beginListening();
  }

  /// After the permission explain screen — request permission then listen.
  Future<void> confirmPermissionAndListen() async {
    if (phase != VoiceGuidancePhase.permissionExplain || !_sessionActive) {
      return;
    }
    phase = VoiceGuidancePhase.permissionRequesting;
    message = MemoraCopy.voicePermissionRequesting;
    notifyListeners();
    final status = await _recognizer.requestPermission();
    if (!_sessionActive) {
      return;
    }
    if (status != SpeechPermissionStatus.granted) {
      _showTerminal(
        VoiceGuidancePhase.permissionDenied,
        MemoraCopy.voicePermissionDenied,
      );
      await _recognizer.release();
      return;
    }
    await _beginListening();
  }

  Future<void> retry() async {
    decision = null;
    suggestedDestination = null;
    message = null;
    recognizedText = null;
    _sessionActive = true;
    final availability = await _recognizer.checkAvailability();
    if (!_sessionActive) {
      return;
    }
    if (availability != SpeechRecognizerAvailability.availableOnDevice) {
      _showTerminal(
        VoiceGuidancePhase.unavailable,
        MemoraCopy.voiceRecognizerUnavailable,
      );
      await _recognizer.release();
      return;
    }
    final permission = await _recognizer.permissionStatus();
    if (!_sessionActive) {
      return;
    }
    if (permission != SpeechPermissionStatus.granted) {
      if (permission == SpeechPermissionStatus.notDetermined) {
        phase = VoiceGuidancePhase.permissionExplain;
        message = MemoraCopy.voicePermissionExplain;
        notifyListeners();
        return;
      }
      _showTerminal(
        VoiceGuidancePhase.permissionDenied,
        MemoraCopy.voicePermissionDenied,
      );
      await _recognizer.release();
      return;
    }
    await _beginListening();
  }

  Future<void> cancel() async {
    await _recognizer.cancel();
    await _recognizer.release();
    _resetIdle();
  }

  /// Release mic on lifecycle pause / navigation away without trapping.
  Future<void> releaseForLifecycle() async {
    if (!isListeningPhase && phase == VoiceGuidancePhase.idle) {
      await _recognizer.release();
      return;
    }
    await _recognizer.cancel();
    await _recognizer.release();
    _resetIdle();
  }

  /// Confirm navigation only after the person presses `Ir a …`.
  Future<UserHomeDestination?> confirmNavigate() async {
    final target = navigationTarget;
    await _recognizer.release();
    _resetIdle();
    return target;
  }

  /// Dismiss outcome chrome and restore unchanged home (tiles stay usable).
  Future<void> dismissToHome() async {
    await _recognizer.release();
    _resetIdle();
  }

  Future<void> _beginListening() async {
    phase = VoiceGuidancePhase.listening;
    message = MemoraCopy.voiceListeningPrompt;
    notifyListeners();

    final outcome = await _recognizer.listen(timeout: listenTimeout);
    if (!_sessionActive) {
      await _recognizer.release();
      return;
    }

    await _handleOutcome(outcome);
  }

  Future<void> _handleOutcome(SpeechListenOutcome outcome) async {
    switch (outcome) {
      case SpeechRecognized(:final textInMemory):
        phase = VoiceGuidancePhase.processing;
        message = MemoraCopy.voiceProcessing;
        recognizedText = textInMemory.trim();
        notifyListeners();
        // The phrase remains in volatile controller memory only long enough to
        // let the person verify what was understood. It is never persisted.
        final result = VoiceRecommendationPolicy.recommend(
          textInMemory: textInMemory,
          content: _contentSnapshot(),
        );
        await _recognizer.release();
        if (!_sessionActive) {
          return;
        }
        _applyDecision(result);

      case SpeechSilence():
        await _recognizer.release();
        _showTerminal(VoiceGuidancePhase.silence, MemoraCopy.voiceSilence);

      case SpeechTimeout():
        await _recognizer.release();
        _showTerminal(VoiceGuidancePhase.timeout, MemoraCopy.voiceTimeout);

      case SpeechCancelled():
        await _recognizer.release();
        _resetIdle();

      case SpeechListenError():
        await _recognizer.release();
        _showTerminal(VoiceGuidancePhase.error, MemoraCopy.voiceListenError);

      case SpeechPermissionDeniedOutcome():
        await _recognizer.release();
        _showTerminal(
          VoiceGuidancePhase.permissionDenied,
          MemoraCopy.voicePermissionDenied,
        );

      case SpeechUnavailableOutcome():
        await _recognizer.release();
        _showTerminal(
          VoiceGuidancePhase.unavailable,
          MemoraCopy.voiceRecognizerUnavailable,
        );
    }
  }

  void _applyDecision(VoiceGuidanceDecision result) {
    decision = result;
    message = result.message;
    suggestedDestination = result.destination;
    phase = switch (result.kind) {
      VoiceGuidanceKind.suggestDestination => VoiceGuidancePhase.suggestion,
      VoiceGuidanceKind.unclear => VoiceGuidancePhase.unclear,
      VoiceGuidanceKind.nothingPrepared => VoiceGuidancePhase.nothingPrepared,
      VoiceGuidanceKind.safetyLimitation => VoiceGuidancePhase.safetyLimitation,
    };
    notifyListeners();
  }

  void _showTerminal(VoiceGuidancePhase next, String copy) {
    phase = next;
    message = copy;
    decision = null;
    suggestedDestination = null;
    notifyListeners();
  }

  void _resetIdle() {
    _sessionActive = false;
    phase = VoiceGuidancePhase.idle;
    message = null;
    recognizedText = null;
    decision = null;
    suggestedDestination = null;
    notifyListeners();
  }
}
