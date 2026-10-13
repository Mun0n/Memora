import 'dart:async';

import 'speech_output_port.dart';

/// Deterministic speech-output fake for tests and non-Android demo hosts.
///
/// Never opens a real synthesizer. Completions are scripted — never estimated
/// from text length. Uttered text is not retained after completion, stop or
/// release.
final class FakeSpeechOutput implements SpeechOutputPort {
  FakeSpeechOutput({
    this.availability = SpeechOutputAvailability.availableOnDevice,
    List<SpeechSpeakOutcome>? nextOutcomes,
    this.autoComplete = true,
  }) : _queue = List<SpeechSpeakOutcome>.of(
         nextOutcomes ?? const <SpeechSpeakOutcome>[],
       );

  SpeechOutputAvailability availability;
  final List<SpeechSpeakOutcome> _queue;

  /// When true, [speak] completes immediately with the next queued outcome
  /// (or [SpeechSpeakCompleted]). When false, callers must [completeCurrent]
  /// or [failCurrent].
  bool autoComplete;

  int checkAvailabilityCount = 0;
  int speakCount = 0;
  int stopCount = 0;
  int releaseCount = 0;

  /// Last speech-rate argument observed by [speak] (for contract tests).
  double? lastSpeechRate;

  /// Text of the in-flight utterance only. Cleared on complete/stop/release.
  String? _activeText;
  Completer<SpeechSpeakOutcome>? _pending;
  var _speaking = false;

  /// Optional override applied on the next [speak] before the queue.
  SpeechSpeakOutcome? forceNextOutcome;

  void enqueue(SpeechSpeakOutcome outcome) => _queue.add(outcome);

  void enqueueAll(Iterable<SpeechSpeakOutcome> outcomes) =>
      _queue.addAll(outcomes);

  void clearQueue() => _queue.clear();

  /// Completes a manual in-flight [speak] (no-op when none pending).
  void completeCurrent([
    SpeechSpeakOutcome outcome = const SpeechSpeakCompleted(),
  ]) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) {
      return;
    }
    _clearActive();
    pending.complete(outcome);
  }

  /// Fails a manual in-flight [speak].
  void failCurrent([String? code]) {
    completeCurrent(SpeechSpeakError(code));
  }

  @override
  bool get isSpeaking => _speaking;

  /// Exposed for privacy tests — must be null when not speaking.
  String? get retainedUtteranceForTest => _activeText;

  @override
  Future<SpeechOutputAvailability> checkAvailability() async {
    checkAvailabilityCount += 1;
    return availability;
  }

  @override
  Future<SpeechSpeakOutcome> speak(
    String text, {
    double speechRate = SpeechOutputPort.defaultSpeechRate,
  }) async {
    speakCount += 1;
    lastSpeechRate = speechRate;

    if (availability != SpeechOutputAvailability.availableOnDevice) {
      return SpeechSpeakUnavailable(availability: availability);
    }

    // Serialize: stop any prior utterance before starting a new one.
    if (_speaking) {
      await stop();
    }

    _speaking = true;
    _activeText = text;
    final completer = Completer<SpeechSpeakOutcome>();
    _pending = completer;

    if (autoComplete) {
      final forced = forceNextOutcome;
      forceNextOutcome = null;
      final outcome =
          forced ??
          (_queue.isNotEmpty
              ? _queue.removeAt(0)
              : const SpeechSpeakCompleted());
      _clearActive();
      completer.complete(outcome);
    }

    return completer.future;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      _clearActive();
      pending.complete(const SpeechSpeakCancelled());
    } else {
      _clearActive();
    }
  }

  @override
  Future<void> release() async {
    releaseCount += 1;
    await stop();
    _queue.clear();
    forceNextOutcome = null;
    lastSpeechRate = null;
  }

  void _clearActive() {
    _speaking = false;
    _activeText = null;
    _pending = null;
  }
}
