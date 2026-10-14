import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ConversationPromptHelp', () {
    test('requires cue and/or memory reference', () {
      expect(() => ConversationPromptHelp(), throwsArgumentError);
      expect(() => ConversationPromptHelp(cue: '   '), throwsArgumentError);
    });

    test('trims cue and rejects overlong cue', () {
      final help = ConversationPromptHelp(cue: '  Pista Demo  ');
      expect(help.cue, 'Pista Demo');
      expect(help.hasCue, isTrue);
      expect(() => ConversationPromptHelp(cue: 'x' * 161), throwsArgumentError);
    });

    test('memory-only help is valid at construction', () {
      final help = ConversationPromptHelp(
        memoryId: OfflineFixtures.gardenMemoryId,
      );
      expect(help.hasCue, isFalse);
      expect(help.hasMemoryReference, isTrue);
    });

    test('cue remains usable when memory missing; memory-only does not', () {
      final family = IdentityFixtures.familiaEjemploSpaceId;
      final withCue = ConversationPromptHelp(
        cue: 'Pista del huerto Ejemplo',
        memoryId: OfflineFixtures.gardenMemoryId,
      );
      expect(
        withCue.isUsable(familySpaceId: family, resolvedMemory: null),
        isTrue,
      );

      final memoryOnly = ConversationPromptHelp(
        memoryId: OfflineFixtures.gardenMemoryId,
      );
      expect(
        memoryOnly.isUsable(familySpaceId: family, resolvedMemory: null),
        isFalse,
      );
      expect(
        memoryOnly.isUsable(
          familySpaceId: family,
          resolvedMemory: OfflineFixtures.gardenMemory,
        ),
        isTrue,
      );
    });

    test('rejects cross-family or unapproved memory for usability', () {
      final family = IdentityFixtures.familiaEjemploSpaceId;
      final help = ConversationPromptHelp(
        memoryId: OfflineFixtures.gardenMemoryId,
      );
      final proposed = OfflineFixtures.gardenMemory.copyWith(
        lifecycleStatus: MemoryLifecycleStatus.proposed,
      );
      expect(
        help.isUsable(familySpaceId: family, resolvedMemory: proposed),
        isFalse,
      );
      final cross = MemoryEntry(
        id: OfflineFixtures.gardenMemoryId,
        familySpaceId: IdentityFixtures.casaDemoBSpaceId,
        caption: 'Cruzado Demo',
        dateContext: '2020',
        displayOrder: 0,
        lifecycleStatus: MemoryLifecycleStatus.approved,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
      expect(
        help.isUsable(familySpaceId: family, resolvedMemory: cross),
        isFalse,
      );
    });
  });

  group('ConversationPrompt with help', () {
    test('zero-or-one help; reorder keeps help attached', () {
      final a = ConversationPrompt(
        order: 0,
        text: 'Primera invitación Demo',
        help: ConversationPromptHelp(cue: 'Pista A Demo'),
      );
      final b = ConversationPrompt(order: 1, text: 'Segunda invitación Demo');
      final reordered = <ConversationPrompt>[
        b.copyWith(order: 0),
        a.copyWith(order: 1),
      ];
      expect(reordered[0].help, isNull);
      expect(reordered[1].help?.cue, 'Pista A Demo');
    });

    test('topic accepts at most five help cards via prompt bound', () {
      final prompts = List<ConversationPrompt>.generate(
        5,
        (i) => ConversationPrompt(
          order: i,
          text: 'Invitación Demo $i',
          help: ConversationPromptHelp(cue: 'Pista Demo $i'),
        ),
      );
      final topic = ConversationTopic(
        id: OfflineFixtures.gardenTalkTopicId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Tema Demo',
        introduction: 'Intro Demo',
        prompts: prompts,
        closing: 'Cierre Demo',
        displayOrder: 0,
        lifecycleStatus: ConversationTopicLifecycleStatus.draft,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
      expect(topic.promptHelpCards, hasLength(5));
      expect(topic.promptHelpMemoryIds, isEmpty);
    });
  });

  group('Slice 10 backward compatibility', () {
    test('prompts without help remain valid on garden fixture prompt 1', () {
      final prompt = OfflineFixtures.gardenTalkTopic.prompts[1];
      expect(prompt.help, isNull);
      expect(
        prompt.hasUsableHelp(
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        ),
        isFalse,
      );
    });

    test('prompts without help decode as null help card', () {
      final prompt = ConversationPrompt(order: 0, text: 'Sin ayuda Demo');
      expect(prompt.help, isNull);
      expect(prompt.copyWith(text: 'Sin ayuda Demo').help, isNull);
      expect(
        prompt
            .copyWith(help: ConversationPromptHelp(cue: 'Nueva pista Demo'))
            .help
            ?.cue,
        'Nueva pista Demo',
      );
      expect(
        prompt
            .copyWith(help: ConversationPromptHelp(cue: 'Nueva pista Demo'))
            .copyWith(clearHelp: true)
            .help,
        isNull,
      );
    });
  });
}
