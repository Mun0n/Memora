import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// Turn-based guided conversation session for the supported person.
///
/// Holds speech and session state only in memory. Never persists transcripts,
/// topic choice metrics or answers. Speech output and recognition are
/// serialized: the microphone opens only after Memora finishes speaking.
final class UserConversationSessionController extends ChangeNotifier {
  UserConversationSessionController({
    required SpeechRecognizerPort recognizer,
    SpeechOutputPort? speechOutput,
    ConversationEnginePort? engine,
    Duration postSpeakPause = const Duration(milliseconds: 400),
  }) : _recognizer = recognizer,
       _speechOutput = speechOutput ?? FakeSpeechOutput(),
       _engine = engine ?? DeterministicConversationEngine(),
       _postSpeakPause = postSpeakPause;

  final SpeechRecognizerPort _recognizer;
  final SpeechOutputPort _speechOutput;
  final ConversationEnginePort _engine;
  final Duration _postSpeakPause;

  ConversationSessionSnapshot snapshot = ConversationSessionSnapshot.empty;
  bool isListenInFlight = false;
  bool isMemoraSpeaking = false;
  bool speechUnavailable = false;
  bool speechOutputUnavailable = false;

  /// Guards every async speak/listen completion. Bumped on cancel, navigation,
  /// lifecycle, topic change, finish and repeat so stale callbacks never reopen
  /// the microphone.
  var _turnGeneration = 0;

  ConversationSessionPhase get phase => snapshot.phase;

  bool get microphoneOpen => snapshot.microphoneOpen;

  bool get hasActiveSession => snapshot.hasActiveSession;

  ConversationTopic? get topic => snapshot.topic;

  String get displayedText => snapshot.displayedText;

  /// True while Memora is uttering family-authored or fixed copy.
  bool get memoraSpeaking => isMemoraSpeaking;

  /// Written flow + manual [beginManualListen] when no local voice qualifies.
  bool get needsManualListen =>
      speechOutputUnavailable &&
      phase == ConversationSessionPhase.promptReady &&
      !microphoneOpen &&
      !isListenInFlight;

  /// Explicit start after the person chooses a topic.
  Future<void> start(ConversationTopic topic) async {
    final generation = ++_turnGeneration;
    // Stop prior resources without [SpeechOutputPort.release] so scripted test
    // outcomes queued on the fake survive across an explicit new start.
    await _stopListeningQuietly(bumpGeneration: false);
    await _speechOutput.stop();
    isMemoraSpeaking = false;
    snapshot = _engine.start(topic);
    speechUnavailable = false;
    speechOutputUnavailable = false;
    isListenInFlight = false;
    notifyListeners();
    await _runSpokenOpening(generation);
  }

  /// Advances introduction → first prompt when local speech output is absent.
  Future<void> confirmIntroduction() async {
    if (snapshot.phase != ConversationSessionPhase.topicIntroduction) {
      return;
    }
    final generation = _turnGeneration;
    snapshot = _engine.confirmIntroduction();
    notifyListeners();
    if (speechOutputUnavailable) {
      // Manual Hablar starts listening — do not auto-open the mic.
      return;
    }
    if (!await _speakCurrentText(generation)) {
      return;
    }
    await _pauseThenListen(generation);
  }

  /// Manual listen start when local speech output is unavailable.
  Future<void> beginManualListen() async {
    if (!needsManualListen &&
        phase != ConversationSessionPhase.promptReady &&
        phase != ConversationSessionPhase.acknowledgement) {
      return;
    }
    if (phase == ConversationSessionPhase.acknowledgement) {
      final generation = _turnGeneration;
      snapshot = _engine.applyControl(
        ConversationControlAction.finishedSpeaking,
      );
      notifyListeners();
      if (snapshot.phase == ConversationSessionPhase.promptReady) {
        await _maybeBeginListening(generation);
      }
      return;
    }
    await _maybeBeginListening(_turnGeneration);
  }

  Future<void> finishedSpeaking() async {
    final generation = _turnGeneration;
    if (snapshot.phase == ConversationSessionPhase.listening) {
      await _stopListeningQuietly(bumpGeneration: false);
      snapshot = _engine.applyControl(
        ConversationControlAction.finishedSpeaking,
      );
      notifyListeners();
      await _afterPersonTurn(generation);
      return;
    }
    if (snapshot.phase == ConversationSessionPhase.acknowledgement) {
      snapshot = _engine.applyControl(
        ConversationControlAction.finishedSpeaking,
      );
      notifyListeners();
      await _afterAdvanceFromAcknowledgement(generation);
      return;
    }
    if (snapshot.phase == ConversationSessionPhase.promptReady) {
      if (speechOutputUnavailable) {
        await beginManualListen();
        return;
      }
      snapshot = _engine.applyControl(
        ConversationControlAction.finishedSpeaking,
      );
      notifyListeners();
      await _afterPersonTurn(generation);
    }
  }

  Future<void> repeat() async {
    final generation = ++_turnGeneration;
    await _stopListeningQuietly(bumpGeneration: false);
    await _speechOutput.stop();
    isMemoraSpeaking = false;
    snapshot = _engine.applyControl(ConversationControlAction.repeat);
    notifyListeners();
    if (speechOutputUnavailable) {
      return;
    }
    if (!await _speakCurrentText(generation)) {
      return;
    }
    await _pauseThenListen(generation);
  }

  Future<void> changeTopic() async {
    await _stopAllQuietly();
    snapshot = _engine.applyControl(ConversationControlAction.changeTopic);
    notifyListeners();
  }

  Future<void> finish() async {
    final generation = ++_turnGeneration;
    await _stopListeningQuietly(bumpGeneration: false);
    await _speechOutput.stop();
    isMemoraSpeaking = false;
    snapshot = _engine.applyControl(ConversationControlAction.finish);
    notifyListeners();
    if (!speechOutputUnavailable &&
        snapshot.phase == ConversationSessionPhase.closing) {
      await _speakCurrentText(generation);
    }
  }

  /// App pause, navigation away or home — release mic/TTS and clear session.
  Future<void> releaseForLifecycle() async {
    await _stopAllQuietly();
    if (snapshot.hasActiveSession ||
        snapshot.phase == ConversationSessionPhase.cancelled) {
      snapshot = _engine.cancel();
      snapshot = _engine.clear();
    }
    isListenInFlight = false;
    isMemoraSpeaking = false;
    notifyListeners();
  }

  Future<void> clear() async {
    await _stopAllQuietly();
    snapshot = _engine.clear();
    isListenInFlight = false;
    isMemoraSpeaking = false;
    speechUnavailable = false;
    speechOutputUnavailable = false;
    notifyListeners();
  }

  Future<void> _runSpokenOpening(int generation) async {
    final availability = await _speechOutput.checkAvailability();
    if (generation != _turnGeneration) {
      return;
    }
    if (availability != SpeechOutputAvailability.availableOnDevice) {
      speechOutputUnavailable = true;
      notifyListeners();
      return;
    }

    if (!await _speakCurrentText(generation)) {
      return;
    }
    if (generation != _turnGeneration) {
      return;
    }

    snapshot = _engine.confirmIntroduction();
    notifyListeners();

    if (!await _speakCurrentText(generation)) {
      return;
    }
    await _pauseThenListen(generation);
  }

  Future<void> _afterPersonTurn(int generation) async {
    if (generation != _turnGeneration) {
      return;
    }
    if (snapshot.phase == ConversationSessionPhase.safetyStopped ||
        snapshot.phase == ConversationSessionPhase.unavailable ||
        snapshot.phase == ConversationSessionPhase.cancelled ||
        snapshot.phase == ConversationSessionPhase.closing) {
      return;
    }
    if (snapshot.phase != ConversationSessionPhase.acknowledgement) {
      return;
    }
    if (speechOutputUnavailable) {
      return;
    }
    if (!await _speakCurrentText(generation)) {
      return;
    }
    if (generation != _turnGeneration) {
      return;
    }
    snapshot = _engine.applyControl(ConversationControlAction.finishedSpeaking);
    notifyListeners();
    await _afterAdvanceFromAcknowledgement(generation);
  }

  Future<void> _afterAdvanceFromAcknowledgement(int generation) async {
    if (generation != _turnGeneration) {
      return;
    }
    if (snapshot.phase == ConversationSessionPhase.closing) {
      if (!speechOutputUnavailable) {
        await _speakCurrentText(generation);
      }
      return;
    }
    if (snapshot.phase != ConversationSessionPhase.promptReady) {
      return;
    }
    if (speechOutputUnavailable) {
      return;
    }
    if (!await _speakCurrentText(generation)) {
      return;
    }
    await _pauseThenListen(generation);
  }

  /// Speaks [snapshot.displayedText]. Returns true only on clean completion.
  Future<bool> _speakCurrentText(int generation) async {
    final text = snapshot.displayedText.trim();
    if (text.isEmpty) {
      return true;
    }
    if (generation != _turnGeneration) {
      return false;
    }

    // Never listen while Memora speaks.
    await _recognizer.release();
    if (generation != _turnGeneration) {
      return false;
    }

    isMemoraSpeaking = true;
    notifyListeners();

    final outcome = await _speechOutput.speak(text);

    if (generation != _turnGeneration) {
      return false;
    }

    isMemoraSpeaking = false;
    notifyListeners();

    return switch (outcome) {
      SpeechSpeakCompleted() => true,
      SpeechSpeakCancelled() => false,
      SpeechSpeakError() => _markOutputUnavailable(),
      SpeechSpeakUnavailable() => _markOutputUnavailable(),
    };
  }

  bool _markOutputUnavailable() {
    speechOutputUnavailable = true;
    isMemoraSpeaking = false;
    notifyListeners();
    return false;
  }

  Future<void> _pauseThenListen(int generation) async {
    if (generation != _turnGeneration) {
      return;
    }
    if (_postSpeakPause > Duration.zero) {
      await Future<void>.delayed(_postSpeakPause);
    }
    if (generation != _turnGeneration) {
      return;
    }
    await _maybeBeginListening(generation);
  }

  Future<void> _maybeBeginListening(int generation) async {
    if (generation != _turnGeneration) {
      return;
    }
    if (isMemoraSpeaking || _speechOutput.isSpeaking) {
      return;
    }
    if (snapshot.phase != ConversationSessionPhase.promptReady) {
      return;
    }
    final availability = await _recognizer.checkAvailability();
    if (generation != _turnGeneration) {
      return;
    }
    if (availability != SpeechRecognizerAvailability.availableOnDevice) {
      speechUnavailable = true;
      snapshot = _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.unavailable,
      );
      notifyListeners();
      return;
    }

    var permission = await _recognizer.permissionStatus();
    if (generation != _turnGeneration) {
      return;
    }
    if (permission == SpeechPermissionStatus.notDetermined) {
      permission = await _recognizer.requestPermission();
    }
    if (generation != _turnGeneration) {
      return;
    }
    if (permission == SpeechPermissionStatus.denied ||
        permission == SpeechPermissionStatus.permanentlyDenied) {
      speechUnavailable = true;
      snapshot = _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.permissionDenied,
      );
      notifyListeners();
      return;
    }

    snapshot = _engine.beginListening();
    notifyListeners();
    if (!snapshot.microphoneOpen) {
      return;
    }

    isListenInFlight = true;
    notifyListeners();
    SpeechListenOutcome outcome;
    try {
      outcome = await _recognizer.listen();
    } finally {
      if (generation == _turnGeneration) {
        isListenInFlight = false;
        await _recognizer.release();
      }
    }

    if (generation != _turnGeneration) {
      return;
    }

    snapshot = _mapListenOutcome(outcome);
    notifyListeners();
    await _afterPersonTurn(generation);
  }

  ConversationSessionSnapshot _mapListenOutcome(SpeechListenOutcome outcome) {
    return switch (outcome) {
      SpeechRecognized(:final textInMemory) => _engine.onSpeechResult(
        textInMemory: textInMemory,
        outcome: ConversationSpeechOutcome.recognized,
      ),
      SpeechSilence() || SpeechTimeout() => _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.silence,
      ),
      SpeechCancelled() => _engine.applyControl(
        ConversationControlAction.finishedSpeaking,
      ),
      SpeechListenError() => _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.recognitionFailure,
      ),
      SpeechPermissionDeniedOutcome() => _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.permissionDenied,
      ),
      SpeechUnavailableOutcome() => _engine.onSpeechResult(
        textInMemory: null,
        outcome: ConversationSpeechOutcome.unavailable,
      ),
    };
  }

  Future<void> _stopListeningQuietly({bool bumpGeneration = true}) async {
    if (bumpGeneration) {
      _turnGeneration += 1;
    }
    if (_recognizer.isListening || isListenInFlight) {
      await _recognizer.cancel();
    }
    await _recognizer.release();
    isListenInFlight = false;
  }

  Future<void> _stopAllQuietly({bool bumpGeneration = true}) async {
    if (bumpGeneration) {
      _turnGeneration += 1;
    }
    final wasListening = _recognizer.isListening || isListenInFlight;
    isMemoraSpeaking = false;
    isListenInFlight = false;
    await _speechOutput.stop();
    await _speechOutput.release();
    if (wasListening) {
      await _recognizer.cancel();
    }
    await _recognizer.release();
  }
}
