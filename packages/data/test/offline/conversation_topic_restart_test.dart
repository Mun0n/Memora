import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'topic writes survive snapshot restart and enqueue unique outbox keys',
    () async {
      final live = InMemoryOfflineStore();
      final repo = InMemoryConversationTopicRepository(live);
      final configure = ConfigureConversationTopic(repo);

      await configure.create(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.gardenTalkTopicId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: OfflineFixtures.gardenTalkTopic.title,
        introduction: OfflineFixtures.gardenTalkTopic.introduction,
        prompts: OfflineFixtures.gardenTalkTopic.prompts,
        closing: OfflineFixtures.gardenTalkTopic.closing,
        memoryId: OfflineFixtures.gardenTalkTopic.memoryId,
        lifecycleStatus: ConversationTopicLifecycleStatus.active,
        idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
      );
      await configure.create(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.draftKitchenTopicId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: OfflineFixtures.draftKitchenTopic.title,
        introduction: OfflineFixtures.draftKitchenTopic.introduction,
        prompts: OfflineFixtures.draftKitchenTopic.prompts,
        closing: OfflineFixtures.draftKitchenTopic.closing,
        idempotencyKey: IdempotencyKey(
          'demo-topic-save-01932f00-0010-7000-8000-000000001002',
        ),
      );

      final pendingBefore = await live.outbox.listPending();
      expect(
        pendingBefore.any(
          (op) => op.aggregateType == OutboxAggregateType.conversationTopic,
        ),
        isTrue,
      );
      final keys = pendingBefore.map((op) => op.idempotencyKey.value).toSet();
      expect(keys.length, pendingBefore.length);

      final snapshot = live.capture();
      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredRepo = InMemoryConversationTopicRepository(restored);
      final restoredConfigure = ConfigureConversationTopic(restoredRepo);

      final garden = await restoredRepo.findById(
        OfflineFixtures.gardenTalkTopicId,
      );
      expect(garden, isNotNull);
      expect(garden!.title, 'El jardín Demo');
      expect(garden.lifecycleStatus, ConversationTopicLifecycleStatus.active);
      expect(garden.syncState, SyncState.pending);
      expect(garden.prompts, hasLength(2));

      final active = await restoredConfigure.listActiveForViewing(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(active.map((t) => t.id), [OfflineFixtures.gardenTalkTopicId]);

      // Session speech must not appear in snapshot / outbox.
      final joined = restored
          .capture()
          .outboxEntries
          .map((e) => e.idempotencyKey.value)
          .join();
      expect(joined.toLowerCase(), isNot(contains('transcript')));
      expect(joined.toLowerCase(), isNot(contains('audio')));
    },
  );
}
