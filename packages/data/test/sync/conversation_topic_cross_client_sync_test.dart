import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'caregiver topic configure converges through fake authority to user cache',
    () async {
      final authority = InMemorySyncAuthority();
      LocalDemoFictionalBaseline.ensureConversationTopics(authority);

      final caregiverStore = InMemoryOfflineStore();
      final caregiverTopics = InMemoryConversationTopicRepository(
        caregiverStore,
      );
      final caregiverBridge = OfflineSyncBridge(caregiverStore);
      var caregiverConflictSeq = 0;
      final caregiverEngine = SyncEngine(
        outbox: caregiverStore.outbox,
        transport: FakeSupabaseRemote.withAuthority(authority),
        payloadLoader: caregiverBridge,
        applyHandler: caregiverBridge,
        conflicts: InMemoryConflictStore(),
        conflictIdFactory: () {
          caregiverConflictSeq += 1;
          final suffix = caregiverConflictSeq.toString().padLeft(2, '0');
          return '01932f00-0010-7000-8000-000000000a$suffix';
        },
      );

      await caregiverEngine.pull(
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );
      final configure = ConfigureConversationTopic(caregiverTopics);
      final activated = await configure.activate(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.draftKitchenTopicId,
        idempotencyKey: IdempotencyKey('demo-topic-activate-cross'),
      );
      expect(
        activated.lifecycleStatus,
        ConversationTopicLifecycleStatus.active,
      );

      final push = await caregiverEngine.pushPending();
      expect(push.failed, 0);

      final userStore = InMemoryOfflineStore();
      final userTopics = InMemoryConversationTopicRepository(userStore);
      final userBridge = OfflineSyncBridge(userStore);
      var userConflictSeq = 0;
      final userEngine = SyncEngine(
        outbox: userStore.outbox,
        transport: FakeSupabaseRemote.withAuthority(authority),
        payloadLoader: userBridge,
        applyHandler: userBridge,
        conflicts: InMemoryConflictStore(),
        conflictIdFactory: () {
          userConflictSeq += 1;
          final suffix = userConflictSeq.toString().padLeft(2, '0');
          return '01932f00-0010-7000-8000-000000000b$suffix';
        },
      );
      await userEngine.pull(
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );

      final active = await ConfigureConversationTopic(userTopics)
          .listActiveForViewing(
            actor: IdentityFixtures.amparoSupportedMembership,
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          );
      expect(
        active.map((t) => t.id.value),
        containsAll(<String>[
          OfflineFixtures.gardenTalkTopicId.value,
          OfflineFixtures.draftKitchenTopicId.value,
        ]),
      );
      expect(
        active.any((t) => t.id == OfflineFixtures.archivedMusicTopicId),
        isFalse,
      );
    },
  );

  test('delivery failure retains cached active topics', () async {
    final store = InMemoryOfflineStore();
    final topics = InMemoryConversationTopicRepository(store);
    await LocalDemoSharedBootstrap.seedConversationTopicFixturesIfIsolated(
      topics: topics,
      sharedLocalDemo: false,
    );
    final cached = await topics.listActiveForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(cached, isNotEmpty);
    expect(cached.first.title, 'El jardín Demo');

    final failing = _FailingTransport();
    final bridge = OfflineSyncBridge(store);
    var conflictSeq = 0;
    final engine = SyncEngine(
      outbox: store.outbox,
      transport: failing,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflicts: InMemoryConflictStore(),
      conflictIdFactory: () {
        conflictSeq += 1;
        return '01932f00-0010-7000-8000-000000000c${conflictSeq.toString().padLeft(2, '0')}';
      },
    );
    await expectLater(
      engine.pull(familySpaceId: IdentityFixtures.familiaEjemploSpaceId),
      throwsA(isA<StateError>()),
    );
    final still = await topics.listActiveForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(still.map((t) => t.id), [OfflineFixtures.gardenTalkTopicId]);
  });
}

final class _FailingTransport implements SyncTransportPort {
  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    throw StateError('simulated delivery failure');
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    throw StateError('simulated delivery failure');
  }
}
