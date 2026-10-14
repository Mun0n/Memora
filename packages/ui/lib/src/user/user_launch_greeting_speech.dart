import 'package:domain/domain.dart';

import '../l10n/memora_copy.dart';

/// Speaks the home greeting + invitation once per app launch.
///
/// Uses the existing local [SpeechOutputPort] only. Never opens the microphone,
/// requests recognition permission, persists audio/text or blocks home actions.
/// Failures/cancellation leave the visual home fully usable.
final class UserLaunchGreetingSpeech {
  UserLaunchGreetingSpeech({required SpeechOutputPort speechOutput})
    : _speechOutput = speechOutput;

  final SpeechOutputPort _speechOutput;

  /// True after the single launch attempt (success, skip, cancel or failure).
  var attempted = false;

  var _generation = 0;
  var _inFlight = false;

  bool get inFlight => _inFlight;

  /// Speaks [greeting] then [MemoraCopy.userHomeInvitation] at most once.
  ///
  /// No-op when already attempted, [isOnHome] is false, or local TTS is not
  /// available. Marks [attempted] before speaking so resume/return-home never
  /// retries.
  Future<void> speakOnceIfNeeded({
    required String greeting,
    required bool isOnHome,
  }) async {
    if (attempted || !isOnHome) {
      return;
    }
    attempted = true;
    final generation = ++_generation;
    _inFlight = true;

    try {
      final availability = await _speechOutput.checkAvailability();
      if (generation != _generation) {
        return;
      }
      if (availability != SpeechOutputAvailability.availableOnDevice) {
        return;
      }

      final safeGreeting = greeting.trim().isEmpty
          ? MemoraCopy.userHomeGreeting
          : greeting.trim();
      final greetingOutcome = await _speechOutput.speak(safeGreeting);
      if (generation != _generation) {
        return;
      }
      if (greetingOutcome is! SpeechSpeakCompleted) {
        return;
      }

      final invitationOutcome = await _speechOutput.speak(
        MemoraCopy.userHomeInvitation,
      );
      if (generation != _generation) {
        return;
      }
      // Invitation failure still leaves the visual home usable.
      if (invitationOutcome is SpeechSpeakCompleted) {
        return;
      }
    } finally {
      if (generation == _generation) {
        _inFlight = false;
      }
    }
  }

  /// Stops an in-flight launch greeting so another speech flow can proceed.
  Future<void> cancel() async {
    _generation += 1;
    if (!_inFlight && !_speechOutput.isSpeaking) {
      return;
    }
    _inFlight = false;
    await _speechOutput.stop();
  }
}
