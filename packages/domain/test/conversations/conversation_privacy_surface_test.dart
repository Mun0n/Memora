import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'session speech never appears on topic aggregate or outbox type list',
    () {
      final topic = OfflineFixtures.gardenTalkTopic;
      expect(topic.title, isNot(contains('transcript')));
      // Topic payload fields are structural only.
      expect(topic.prompts.map((p) => p.text).join(), isNotEmpty);

      final outboxTypes = OutboxAggregateType.values.map((e) => e.name).toSet();
      expect(outboxTypes, contains('conversationTopic'));
      expect(outboxTypes, isNot(contains('conversationSession')));
      expect(outboxTypes, isNot(contains('transcript')));
      expect(outboxTypes, isNot(contains('audio')));
    },
  );

  test(
    'engine holds ephemeral text only in returned snapshot display copy',
    () {
      final engine = DeterministicConversationEngine();
      engine.start(OfflineFixtures.gardenTalkTopic);
      engine.confirmIntroduction();
      engine.beginListening();
      final snap = engine.onSpeechResult(
        textInMemory: 'Respuesta secreta Demo que no debe persistir',
      );
      expect(snap.displayedText, ConversationCopy.neutralAcknowledgement);
      expect(snap.displayedText, isNot(contains('Respuesta secreta')));
      engine.clear();
      expect(engine.snapshot.displayedText, isEmpty);
      expect(engine.snapshot.topic, isNull);
    },
  );

  test(
    'no LLM / generative / remote speech dependency in conversation copy',
    () {
      expect(ConversationCopy.neutralAcknowledgement, isNot(contains('IA')));
      expect(
        ConversationCopy.neutralAcknowledgement,
        isNot(contains('modelo')),
      );
      expect(ConversationCopy.safetyLimitation, contains('emergencias'));
      expect(ConversationCopy.requestHelpLabel, 'Dame una idea');
      expect(ConversationCopy.helpUnavailable, isNot(contains('IA')));
      expect(ConversationCopy.caregiverHelpGuidance, contains('contexto'));
    },
  );

  test('help usage stays out of outbox types and export exclusions', () {
    final outboxTypes = OutboxAggregateType.values.map((e) => e.name).toSet();
    expect(outboxTypes, isNot(contains('helpUse')));
    expect(outboxTypes, isNot(contains('displayedMemoryHistory')));
    expect(
      FamilyContentScope.excludedConversationSessionSurfaces,
      containsAll(<String>[
        'helpUseEvent',
        'displayedMemoryHistory',
        'revealedHelpHistory',
      ]),
    );
    // Authored help rides on the topic aggregate as family content.
    expect(OfflineFixtures.gardenTalkTopic.prompts[0].help, isNotNull);
  });

  test('speech-output fallback copy stays written and manual', () {
    expect(ConversationCopy.speechOutputUnavailable, contains('Hablar'));
    expect(ConversationCopy.manualSpeakLabel, 'Hablar');
    expect(ConversationCopy.memoraSpeakingLabel, 'Memora está hablando');
    expect(ConversationCopy.listeningLabel, 'Te escucho');
    expect(ConversationCopy.speechOutputUnavailable, isNot(contains('red')));
    expect(ConversationCopy.speechOutputUnavailable, isNot(contains('nube')));
  });
}
