import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late DeterministicConversationEngine engine;
  late ConversationTopic topic;

  setUp(() {
    engine = DeterministicConversationEngine();
    topic = OfflineFixtures.gardenTalkTopic;
  });

  test('explicit start → introduction → prompt → listen → ack → next', () {
    var snap = engine.start(topic);
    expect(snap.phase, ConversationSessionPhase.topicIntroduction);
    expect(snap.displayedText, topic.introduction);
    expect(snap.microphoneOpen, isFalse);

    snap = engine.confirmIntroduction();
    expect(snap.phase, ConversationSessionPhase.promptReady);
    expect(snap.displayedText, topic.prompts[0].text);
    expect(snap.microphoneOpen, isFalse);

    snap = engine.beginListening();
    expect(snap.phase, ConversationSessionPhase.listening);
    expect(snap.microphoneOpen, isTrue);

    snap = engine.onSpeechResult(textInMemory: 'Me gustaban las rosas Demo');
    expect(snap.microphoneOpen, isFalse);
    expect(snap.phase, ConversationSessionPhase.acknowledgement);
    expect(snap.displayedText, ConversationCopy.neutralAcknowledgement);
    expect(snap.displayedText.toLowerCase(), isNot(contains('entendido')));
    expect(snap.displayedText.toLowerCase(), isNot(contains('correcto')));

    snap = engine.advanceAfterAcknowledgement();
    expect(snap.phase, ConversationSessionPhase.promptReady);
    expect(snap.promptIndex, 1);
    expect(snap.displayedText, topic.prompts[1].text);
    expect(snap.microphoneOpen, isFalse);
  });

  test('long ordinary answer advances without scoring', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    final long =
        'En el jardín Ejemplo plantaba tomates y flores con calma '
        'todas las mañanas de la casa Demo y también regaba las macetas.';
    final snap = engine.onSpeechResult(textInMemory: long);
    expect(snap.phase, ConversationSessionPhase.acknowledgement);
    expect(snap.displayedText, ConversationCopy.neutralAcknowledgement);
  });

  test('silence, no me acuerdo, repeat, change topic, finish', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();

    var snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.silence,
    );
    expect(snap.displayedText, ConversationCopy.silenceRecovery);
    expect(snap.microphoneOpen, isFalse);

    snap = engine.onSpeechResult(textInMemory: 'No me acuerdo');
    expect(snap.displayedText, ConversationCopy.noMeAcuerdoRecovery);
    expect(snap.lastCommand, ConversationCommand.noMeAcuerdo);

    snap = engine.applyControl(ConversationControlAction.repeat);
    expect(snap.phase, ConversationSessionPhase.promptReady);
    expect(snap.displayedText, topic.prompts[0].text);

    snap = engine.applyControl(ConversationControlAction.changeTopic);
    expect(snap.phase, ConversationSessionPhase.cancelled);
    expect(snap.microphoneOpen, isFalse);

    engine.clear();
    engine.start(topic);
    engine.confirmIntroduction();
    snap = engine.applyControl(ConversationControlAction.finish);
    expect(snap.phase, ConversationSessionPhase.closing);
    expect(snap.displayedText, topic.closing);
    expect(snap.microphoneOpen, isFalse);
  });

  test('recognition failure and unavailable keep exits usable', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    var snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.recognitionFailure,
    );
    expect(snap.displayedText, ConversationCopy.recognitionFailureRecovery);
    expect(snap.microphoneOpen, isFalse);

    snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.unavailable,
    );
    expect(snap.phase, ConversationSessionPhase.unavailable);
    expect(snap.displayedText, ConversationCopy.unavailable);
  });

  test('permission denial keeps written exits usable without listening', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    final snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.permissionDenied,
    );
    expect(snap.phase, ConversationSessionPhase.unavailable);
    expect(snap.displayedText, ConversationCopy.unavailable);
    expect(snap.microphoneOpen, isFalse);
  });

  test('safety language stops listening with fixed limitation', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    final snap = engine.onSpeechResult(textInMemory: 'Llama a emergencias');
    expect(snap.phase, ConversationSessionPhase.safetyStopped);
    expect(snap.safetyStopped, isTrue);
    expect(snap.microphoneOpen, isFalse);
    expect(snap.displayedText, ConversationCopy.safetyLimitation);
    expect(
      snap.displayedText.toLowerCase(),
      contains('no es un servicio médico'),
    );
  });

  test('cancel and clear release mic and wipe session', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    expect(engine.snapshot.microphoneOpen, isTrue);
    var snap = engine.cancel();
    expect(snap.phase, ConversationSessionPhase.cancelled);
    expect(snap.microphoneOpen, isFalse);
    snap = engine.clear();
    expect(snap.topic, isNull);
    expect(snap.phase, ConversationSessionPhase.idle);
  });

  test('never listens while acknowledging / never opens mic on intro', () {
    engine.start(topic);
    expect(engine.beginListening().microphoneOpen, isFalse);
    engine.confirmIntroduction();
    engine.beginListening();
    engine.onSpeechResult(textInMemory: 'Algo Demo');
    expect(engine.beginListening().microphoneOpen, isFalse);
  });

  test('FakeConversationEngine counters and no persistence surface', () {
    final fake = FakeConversationEngine();
    fake.start(topic);
    fake.confirmIntroduction();
    fake.beginListening();
    fake.onSpeechResult(textInMemory: 'Hola Demo');
    fake.cancel();
    fake.clear();
    expect(fake.startCount, 1);
    expect(fake.beginListeningCount, 1);
    expect(fake.speechResultCount, 1);
    expect(fake.cancelCount, 1);
    expect(fake.clearCount, 1);
  });

  test('closing after last prompt', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    engine.onSpeechResult(textInMemory: 'Primera respuesta Demo');
    engine.advanceAfterAcknowledgement();
    engine.beginListening();
    engine.onSpeechResult(textInMemory: 'Segunda respuesta Demo');
    final snap = engine.advanceAfterAcknowledgement();
    expect(snap.phase, ConversationSessionPhase.closing);
    expect(snap.displayedText, topic.closing);
    expect(snap.microphoneOpen, isFalse);
  });
}
