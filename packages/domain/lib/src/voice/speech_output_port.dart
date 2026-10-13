/// Whether a qualifying local Spanish speech-output voice is usable.
///
/// Only [availableOnDevice] authorizes spoken prompts. Network-required voices
/// must be rejected — never selected as a silent fallback.
enum SpeechOutputAvailability {
  /// An installed Spanish voice that does not require a network connection.
  availableOnDevice,

  /// No usable local Spanish voice on this device.
  unavailable,

  /// Voices exist but every candidate requires a network connection.
  networkOnlyVoices,
}

/// Distinct outcomes of one ephemeral spoken utterance.
///
/// Implementations must not retain uttered text, audio files or synthesis
/// caches after the outcome is returned or [SpeechOutputPort.release] runs.
sealed class SpeechSpeakOutcome {
  const SpeechSpeakOutcome();
}

/// Utterance finished via a real platform completion callback.
final class SpeechSpeakCompleted extends SpeechSpeakOutcome {
  const SpeechSpeakCompleted();
}

/// Person or host stopped output before completion.
final class SpeechSpeakCancelled extends SpeechSpeakOutcome {
  const SpeechSpeakCancelled();
}

/// Output failed without inventing a timed estimate of completion.
final class SpeechSpeakError extends SpeechSpeakOutcome {
  const SpeechSpeakError([this.code]);

  /// Optional non-sensitive machine code for tests (never utterance text).
  final String? code;
}

/// No qualifying local voice at speak time.
final class SpeechSpeakUnavailable extends SpeechSpeakOutcome {
  const SpeechSpeakUnavailable({
    this.availability = SpeechOutputAvailability.unavailable,
  });

  final SpeechOutputAvailability availability;
}

/// Narrow speech-output port. Platform adapters live behind the app boundary.
///
/// Contract:
/// - Availability is checked before speaking.
/// - On-device Spanish voices only — never silent network fallback.
/// - [speak] completes from a real utterance completion/failure callback, never
///   from text-length or fixed-timer guesses.
/// - Default [defaultSpeechRate] is `0.90` (calm but natural; human-reviewed).
/// - Output is ephemeral platform audio only — no files, cache, logs or sync.
/// - [stop] / [release] end output; they retain no utterance history.
abstract interface class SpeechOutputPort {
  /// Calm but natural Spanish rate for the normal Android path.
  static const double defaultSpeechRate = 0.90;

  /// Check for a qualifying local Spanish voice before speaking.
  Future<SpeechOutputAvailability> checkAvailability();

  /// Speak [text] once. Completes when the platform reports completion/failure.
  ///
  /// [text] is family-authored or reviewed fixed copy. Callers must not log it.
  /// Implementations must not persist it after the returned future settles.
  Future<SpeechSpeakOutcome> speak(
    String text, {
    double speechRate = defaultSpeechRate,
  });

  /// Stop the active utterance immediately (idempotent).
  Future<void> stop();

  /// Release synthesizer resources and clear any in-memory utterance state.
  Future<void> release();

  /// Whether an utterance is currently in progress.
  bool get isSpeaking;
}
