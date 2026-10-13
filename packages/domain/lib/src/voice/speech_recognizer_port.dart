/// Whether an on-device speech recognizer (and language support) is usable.
enum SpeechRecognizerAvailability {
  /// On-device recognition is ready for a short listen session.
  availableOnDevice,

  /// No on-device recognizer on this device.
  unavailable,

  /// Recognizer exists but the needed language pack is missing.
  languagePackMissing,
}

/// Microphone permission as reported before/after an in-context request.
enum SpeechPermissionStatus {
  /// Not yet asked in this composition / process.
  notDetermined,

  /// Granted for a short listen session.
  granted,

  /// Denied; person can retry later from settings or use manual tiles.
  denied,

  /// Permanently denied; do not pressure with repeated system prompts.
  permanentlyDenied,
}

/// Distinct outcomes of one short, tap-gated listen session.
///
/// Recognized text may be held in volatile UI memory so the person can verify
/// what was understood. Implementations must not persist, log, sync or send it.
sealed class SpeechListenOutcome {
  const SpeechListenOutcome();
}

/// On-device recognition returned a short transcript (memory only).
final class SpeechRecognized extends SpeechListenOutcome {
  const SpeechRecognized(this.textInMemory);

  /// Ephemeral utterance text. Callers must not persist or log this value.
  final String textInMemory;
}

/// Listening ended with no usable speech.
final class SpeechSilence extends SpeechListenOutcome {
  const SpeechSilence();
}

/// Calm listening window elapsed without a usable result.
final class SpeechTimeout extends SpeechListenOutcome {
  const SpeechTimeout();
}

/// Person or host cancelled the active listen session.
final class SpeechCancelled extends SpeechListenOutcome {
  const SpeechCancelled();
}

/// Recognizer failed without a transcript.
final class SpeechListenError extends SpeechListenOutcome {
  const SpeechListenError([this.code]);

  /// Optional non-sensitive machine code for tests (never a transcript).
  final String? code;
}

/// Permission was denied when starting listen (or during request).
final class SpeechPermissionDeniedOutcome extends SpeechListenOutcome {
  const SpeechPermissionDeniedOutcome({this.permanent = false});

  final bool permanent;
}

/// On-device recognition / language pack unavailable at listen time.
final class SpeechUnavailableOutcome extends SpeechListenOutcome {
  const SpeechUnavailableOutcome({
    this.availability = SpeechRecognizerAvailability.unavailable,
  });

  final SpeechRecognizerAvailability availability;
}

/// Small speech-recognizer port. Platform adapters live behind the app boundary.
///
/// Contract:
/// - Nothing listens until the host calls [listen] after an explicit tap.
/// - Availability is checked before permission or listening.
/// - On-device only — never silent network fallback.
/// - Microphone is released via [release] on completion, cancel, pause, navigate.
abstract interface class SpeechRecognizerPort {
  /// Check on-device availability before requesting permission or listening.
  Future<SpeechRecognizerAvailability> checkAvailability();

  /// Current permission without prompting.
  Future<SpeechPermissionStatus> permissionStatus();

  /// In-context permission request (after plain-language explanation in UI).
  Future<SpeechPermissionStatus> requestPermission();

  /// Start one short listen session. Must not continue in the background.
  Future<SpeechListenOutcome> listen({Duration? timeout});

  /// Cancel an active listen session and stop capturing.
  Future<void> cancel();

  /// Release microphone / recognizer resources (idempotent).
  Future<void> release();

  /// Whether a listen session is currently active.
  bool get isListening;
}
