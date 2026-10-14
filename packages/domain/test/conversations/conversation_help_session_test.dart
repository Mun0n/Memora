import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late DeterministicConversationEngine engine;
  late ConversationTopic topic;

  setUp(() {
    engine = DeterministicConversationEngine();
    topic = OfflineFixtures.gardenTalkTopic;
  });

  test('exact Dame una idea reveals authored cue without advancing prompt', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    final indexBefore = engine.snapshot.promptIndex;

    var snap = engine.onSpeechResult(textInMemory: 'Dame una idea');
    expect(snap.lastCommand, ConversationCommand.help);
    expect(snap.phase, ConversationSessionPhase.presentingHelp);
    expect(snap.microphoneOpen, isFalse);
    expect(snap.helpRevealed, isTrue);
    expect(snap.displayedText, topic.prompts[0].help!.cue);
    expect(snap.promptIndex, indexBefore);

    snap = engine.completeHelpPresentation();
    expect(snap.phase, ConversationSessionPhase.promptReady);
    expect(snap.promptIndex, indexBefore);
    expect(snap.displayedText, topic.prompts[0].text);
    expect(snap.microphoneOpen, isFalse);
    expect(snap.helpRevealed, isTrue);
  });

  test('ordinary answer containing idea words does not trigger help', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    final snap = engine.onSpeechResult(
      textInMemory: 'Me gusta la idea de plantar tomates Demo',
    );
    expect(snap.phase, ConversationSessionPhase.acknowledgement);
    expect(snap.displayedText, ConversationCopy.neutralAcknowledgement);
    expect(snap.lastCommand, isNull);
    expect(snap.helpRevealed, isFalse);
  });

  test('silence and recognition failure never reveal help', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    var snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.silence,
    );
    expect(snap.helpRevealed, isFalse);
    expect(snap.displayedText, ConversationCopy.silenceRecovery);

    snap = engine.onSpeechResult(
      textInMemory: null,
      outcome: ConversationSpeechOutcome.recognitionFailure,
    );
    expect(snap.helpRevealed, isFalse);
  });

  test('requestHelp on prompt without usable help returns honest copy', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    engine.onSpeechResult(textInMemory: 'Primera respuesta Demo');
    engine.advanceAfterAcknowledgement();
    expect(engine.snapshot.promptIndex, 1);
    expect(topic.prompts[1].help, isNull);

    final snap = engine.requestHelp();
    expect(snap.displayedText, ConversationCopy.helpUnavailable);
    expect(snap.phase, ConversationSessionPhase.acknowledgement);
    expect(snap.promptIndex, 1);
    expect(snap.helpRevealed, isFalse);
  });

  test('cancel clears revealed help and closes mic', () {
    engine.start(topic);
    engine.confirmIntroduction();
    engine.beginListening();
    engine.applyControl(ConversationControlAction.requestHelp);
    expect(engine.snapshot.helpRevealed, isTrue);
    final snap = engine.cancel();
    expect(snap.phase, ConversationSessionPhase.cancelled);
    expect(snap.microphoneOpen, isFalse);
    expect(snap.helpRevealed, isFalse);
    expect(snap.revealedHelpCue, isNull);
  });

  test('help command matcher uses exact reviewed phrases only', () {
    expect(
      ConversationCommandMatcher.classify('Dame una idea'),
      ConversationCommand.help,
    );
    expect(
      ConversationCommandMatcher.classify('necesito una idea'),
      ConversationCommand.help,
    );
    expect(
      ConversationCommandMatcher.classify('quiero que me des una idea'),
      isNull,
    );
    expect(ConversationCommandMatcher.classify('una idea bonita Demo'), isNull);
  });

  test('memory-only help speaks caption when approved memory resolved', () {
    final memoryHelpTopic = ConversationTopic(
      id: OfflineFixtures.draftKitchenTopicId,
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      title: 'Ayuda memoria Demo',
      introduction: 'Intro ayuda Demo',
      prompts: <ConversationPrompt>[
        ConversationPrompt(
          order: 0,
          text: 'Cuéntame algo del jardín Ejemplo.',
          help: ConversationPromptHelp(
            memoryId: OfflineFixtures.gardenMemoryId,
          ),
        ),
      ],
      closing: 'Cierre Demo',
      displayOrder: 0,
      lifecycleStatus: ConversationTopicLifecycleStatus.active,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    engine.start(memoryHelpTopic);
    engine.confirmIntroduction();
    engine.beginListening();
    final snap = engine.requestHelp(
      resolvedHelpMemory: OfflineFixtures.gardenMemory,
    );
    expect(snap.phase, ConversationSessionPhase.presentingHelp);
    expect(snap.displayedText, OfflineFixtures.gardenMemory.caption);
    expect(snap.revealedHelpMemoryId, OfflineFixtures.gardenMemoryId);
  });
}
