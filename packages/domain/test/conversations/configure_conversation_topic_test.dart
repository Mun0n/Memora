import 'package:domain/domain.dart';
import 'package:test/test.dart';

final class _StubTopics implements ConversationTopicRepository {
  final Map<String, ConversationTopic> _items = <String, ConversationTopic>{};

  @override
  Future<ConversationTopic> save({
    required ConversationTopic topic,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = topic.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<ConversationTopic?> findById(ConversationTopicId id) async =>
      _items[id.value];

  @override
  Future<List<ConversationTopic>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    final listed = _items.values
        .where((t) => t.familySpaceId == familySpaceId)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<List<ConversationTopic>> listActiveForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    final listed = _items.values
        .where((t) => t.familySpaceId == familySpaceId && t.isActiveForViewing)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<ConversationTopic> softDelete({
    required ConversationTopicId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}

ConversationTopicId _id(int n) => ConversationTopicId(
  '01932f00-0010-7000-8000-0000000011${n.toString().padLeft(2, '0')}',
);

List<ConversationPrompt> _onePrompt(String text) => <ConversationPrompt>[
  ConversationPrompt(order: 0, text: text),
];

void main() {
  group('ConversationTopic entity validation', () {
    test('rejects empty/overlong fields and bad prompt counts', () {
      expect(
        () => ConversationTopic(
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: '   ',
          introduction: 'Intro Demo',
          prompts: _onePrompt('Prompt Demo'),
          closing: 'Cierre Demo',
          displayOrder: 0,
          lifecycleStatus: ConversationTopicLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => ConversationTopic(
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Ok Demo',
          introduction: 'i' * 241,
          prompts: _onePrompt('Prompt Demo'),
          closing: 'Cierre Demo',
          displayOrder: 0,
          lifecycleStatus: ConversationTopicLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => ConversationTopic(
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Ok Demo',
          introduction: 'Intro Demo',
          prompts: const <ConversationPrompt>[],
          closing: 'Cierre Demo',
          displayOrder: 0,
          lifecycleStatus: ConversationTopicLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => ConversationTopic(
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Ok Demo',
          introduction: 'Intro Demo',
          prompts: <ConversationPrompt>[
            ConversationPrompt(order: 0, text: 'A'),
            ConversationPrompt(order: 2, text: 'B'),
          ],
          closing: 'Cierre Demo',
          displayOrder: 0,
          lifecycleStatus: ConversationTopicLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
    });

    test('draft and archived are not presentable', () {
      expect(OfflineFixtures.gardenTalkTopic.isActiveForViewing, isTrue);
      expect(OfflineFixtures.draftKitchenTopic.isActiveForViewing, isFalse);
      expect(OfflineFixtures.archivedMusicTopic.isActiveForViewing, isFalse);
    });
  });

  group('ConversationTopicCarePolicy', () {
    test('caregivers edit; supported views; contributor neither', () {
      expect(
        ConversationTopicCarePolicy.canEditTopics(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        ConversationTopicCarePolicy.canEditTopics(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isTrue,
      );
      expect(
        ConversationTopicCarePolicy.canEditTopics(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
      expect(
        ConversationTopicCarePolicy.canEditTopics(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isFalse,
      );
      expect(
        ConversationTopicCarePolicy.canViewTopics(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        ConversationTopicCarePolicy.canViewTopics(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
    });
  });

  group('ConfigureConversationTopic', () {
    late _StubTopics store;
    late ConfigureConversationTopic configure;

    setUp(() {
      store = _StubTopics();
      configure = ConfigureConversationTopic(store);
    });

    test(
      'create edit reorder activate archive; active list hides draft/archived',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        final created = await configure.create(
          actor: elena,
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'El jardín Demo',
          introduction: OfflineFixtures.gardenTalkTopic.introduction,
          prompts: OfflineFixtures.gardenTalkTopic.prompts,
          closing: OfflineFixtures.gardenTalkTopic.closing,
          idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
        );
        expect(created.lifecycleStatus, ConversationTopicLifecycleStatus.draft);
        expect(created.displayOrder, 0);

        final edited = await configure.edit(
          actor: elena,
          id: OfflineFixtures.gardenTalkTopicId,
          title: 'Jardín Familiar Demo',
          idempotencyKey: IdempotencyKey('demo-topic-edit'),
        );
        expect(edited.title, 'Jardín Familiar Demo');

        await configure.create(
          actor: elena,
          id: OfflineFixtures.draftKitchenTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Cocina Ejemplo',
          introduction: OfflineFixtures.draftKitchenTopic.introduction,
          prompts: OfflineFixtures.draftKitchenTopic.prompts,
          closing: OfflineFixtures.draftKitchenTopic.closing,
          idempotencyKey: IdempotencyKey('demo-topic-create-2'),
        );

        final reordered = await configure.reorder(
          actor: elena,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          orderedIds: [
            OfflineFixtures.draftKitchenTopicId,
            OfflineFixtures.gardenTalkTopicId,
          ],
          idempotencyKey: IdempotencyKey('demo-topic-reorder'),
        );
        expect(reordered.map((t) => t.id), [
          OfflineFixtures.draftKitchenTopicId,
          OfflineFixtures.gardenTalkTopicId,
        ]);

        final activated = await configure.activate(
          actor: elena,
          id: OfflineFixtures.gardenTalkTopicId,
          idempotencyKey: IdempotencyKey('demo-topic-activate'),
        );
        expect(
          activated.lifecycleStatus,
          ConversationTopicLifecycleStatus.active,
        );

        await configure.activate(
          actor: elena,
          id: OfflineFixtures.draftKitchenTopicId,
          idempotencyKey: IdempotencyKey('demo-topic-activate-2'),
        );
        await configure.archive(
          actor: elena,
          id: OfflineFixtures.draftKitchenTopicId,
          idempotencyKey: IdempotencyKey('demo-topic-archive'),
        );

        final viewing = await configure.listActiveForViewing(
          actor: IdentityFixtures.amparoSupportedMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
        expect(viewing.map((t) => t.id), [OfflineFixtures.gardenTalkTopicId]);
        expect(viewing.single.title, 'Jardín Familiar Demo');
      },
    );

    test(
      'rejects seventh active topic; invalid edit preserves draft',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        for (var i = 1; i <= 6; i++) {
          await configure.create(
            actor: elena,
            id: _id(i),
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            title: 'Activo Demo $i',
            introduction: 'Introducción Demo $i para prueba de límite.',
            prompts: _onePrompt('Invitación Demo $i para prueba de límite.'),
            closing: 'Cierre Demo $i.',
            lifecycleStatus: ConversationTopicLifecycleStatus.active,
            idempotencyKey: IdempotencyKey('demo-topic-active-$i'),
          );
        }
        await expectLater(
          configure.create(
            actor: elena,
            id: _id(7),
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            title: 'Activo Demo 7',
            introduction: 'Introducción Demo 7 para prueba de límite.',
            prompts: _onePrompt('Invitación Demo 7 para prueba de límite.'),
            closing: 'Cierre Demo 7.',
            lifecycleStatus: ConversationTopicLifecycleStatus.active,
            idempotencyKey: IdempotencyKey('demo-topic-active-7'),
          ),
          throwsStateError,
        );

        await configure.create(
          actor: elena,
          id: OfflineFixtures.gardenTalkTopicId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Radio Tema Demo',
          introduction: 'Intro válida Demo.',
          prompts: _onePrompt('Prompt válido Demo.'),
          closing: 'Cierre válido Demo.',
          idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
        );
        await expectLater(
          configure.edit(
            actor: elena,
            id: OfflineFixtures.gardenTalkTopicId,
            title: '',
            idempotencyKey: IdempotencyKey('demo-topic-invalid-title'),
          ),
          throwsArgumentError,
        );
        final still = await store.findById(OfflineFixtures.gardenTalkTopicId);
        expect(still!.title, 'Radio Tema Demo');
      },
    );

    test('contributor and supported cannot configure', () async {
      await configure.create(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.gardenTalkTopicId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'El jardín Demo',
        introduction: OfflineFixtures.gardenTalkTopic.introduction,
        prompts: OfflineFixtures.gardenTalkTopic.prompts,
        closing: OfflineFixtures.gardenTalkTopic.closing,
        idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
      );

      await expectLater(
        configure.edit(
          actor: IdentityFixtures.luciaContributorMembership,
          id: OfflineFixtures.gardenTalkTopicId,
          title: 'Hack Demo',
          idempotencyKey: IdempotencyKey('demo-contributor-topic-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
      await expectLater(
        configure.activate(
          actor: IdentityFixtures.amparoSupportedMembership,
          id: OfflineFixtures.gardenTalkTopicId,
          idempotencyKey: IdempotencyKey('demo-supported-topic-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });
  });

  group('FamilyContentScope', () {
    test('export/deletion includes conversation topics; excludes session', () {
      expect(FamilyContentScope.includesConversationTopics(), isTrue);
      expect(
        FamilyContentScope.exportAndDeletion,
        contains(FamilyContentType.conversationTopics),
      );
      expect(
        FamilyContentScope.excludedConversationSessionSurfaces,
        containsAll(<String>[
          'audio',
          'transcript',
          'answerContent',
          'conversationHistory',
        ]),
      );
    });
  });
}
