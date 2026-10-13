import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// Wires fictional in-memory adapters + demo sync transport for caregiver web.
///
/// Default: private in-process [FakeSupabaseRemote] (isolated local demo).
/// With `--dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=...` (or [localDemoSyncUrl]):
/// [LocalDemoSyncTransport] against the shared loopback demo server.
final class FamilyWebDemoComposition {
  FamilyWebDemoComposition({
    InMemoryOfflineStore? store,
    FamilyMembership? actor,
    bool? networkAvailable,
    this.sessionBoundary = SessionBoundary.demo,
    SyncTransportPort? transport,
    FakeSupabaseRemote? remote,
    String? localDemoSyncUrl,
    bool? sharedLocalDemoTransport,
  }) : store = store ?? InMemoryOfflineStore(),
       transport =
           transport ??
           remote ??
           createDemoSyncTransport(baseUrl: localDemoSyncUrl),
       usesSharedLocalDemoTransport =
           sharedLocalDemoTransport ??
           ((transport ?? remote) is LocalDemoSyncTransport ||
               ((transport ?? remote) == null &&
                   isSharedLocalDemoTransportConfigured(
                     baseUrl: localDemoSyncUrl,
                   ))) {
    final membership = actor ?? IdentityFixtures.elenaPrimaryMembership;
    final resolvedNetwork = networkAvailable ?? usesSharedLocalDemoTransport;
    final scope = usesSharedLocalDemoTransport
        ? DemoDataScope.sharedLocalDemo
        : DemoDataScope.isolatedLocal;
    routines = InMemoryRoutineRepository(this.store);
    reminders = InMemoryReminderRepository(this.store);
    pastimes = InMemoryPastimeRepository(this.store);
    conversationTopics = InMemoryConversationTopicRepository(this.store);
    memories = InMemoryMemoryRepository(this.store);
    weights = InMemoryWeightObservationRepository(this.store);
    bloodPressures = InMemoryBloodPressureObservationRepository(this.store);
    conflicts = InMemoryConflictStore();
    audit = InMemoryAuditStore();
    privacyStore = InMemoryPrivacyStore();
    bridge = OfflineSyncBridge(this.store);
    engine = SyncEngine(
      outbox: this.store.outbox,
      transport: this.transport,
      conflicts: conflicts,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflictIdFactory: () {
        _conflictSeq += 1;
        final suffix = _conflictSeq.toString().padLeft(2, '0');
        return '01932f00-0006-7000-8000-0000000009$suffix';
      },
    );
    privacy = PrivacyWorkflow(audit: audit, store: privacyStore);
    controller = FamilyRoutineController(
      actor: membership,
      routines: routines,
      reminders: reminders,
      networkAvailable: resolvedNetwork,
    );
    pastimeController = FamilyPastimeController(
      actor: membership,
      pastimes: pastimes,
      networkAvailable: resolvedNetwork,
      demoDataScope: scope,
    );
    conversationTopicController = FamilyConversationTopicController(
      actor: membership,
      topics: conversationTopics,
      networkAvailable: resolvedNetwork,
      demoDataScope: scope,
    );
    memoryController = FamilyMemoryController(
      actor: membership,
      memories: memories,
      networkAvailable: resolvedNetwork,
    );
    observationController = FamilyObservationController(
      actor: membership,
      weights: weights,
      bloodPressures: bloodPressures,
      networkAvailable: resolvedNetwork,
      clock: DateTime(2026, 10, 10, 12, 0),
    );
    syncController = SyncPresentationController(
      actor: membership,
      engine: engine,
      conflicts: conflicts,
      sessionBoundary: sessionBoundary,
    );
    privacyController = PrivacyPresentationController(
      actor: membership,
      privacy: privacy,
      sessionBoundary: sessionBoundary,
      clock: DateTime.utc(2026, 10, 10, 12, 0),
    );
    if (usesSharedLocalDemoTransport) {
      pastimeController.afterLocalWrite = syncController.quietPush;
      pastimeController.quietRemotePull = syncController.quietPull;
      conversationTopicController.afterLocalWrite = syncController.quietPush;
      conversationTopicController.quietRemotePull = syncController.quietPull;
    }
  }

  final InMemoryOfflineStore store;
  final SyncTransportPort transport;
  final bool usesSharedLocalDemoTransport;
  final SessionBoundary sessionBoundary;
  late final InMemoryRoutineRepository routines;
  late final InMemoryReminderRepository reminders;
  late final InMemoryPastimeRepository pastimes;
  late final InMemoryConversationTopicRepository conversationTopics;
  late final InMemoryMemoryRepository memories;
  late final InMemoryWeightObservationRepository weights;
  late final InMemoryBloodPressureObservationRepository bloodPressures;
  late final InMemoryConflictStore conflicts;
  late final InMemoryAuditStore audit;
  late final InMemoryPrivacyStore privacyStore;
  late final OfflineSyncBridge bridge;
  late final SyncEngine engine;
  late final PrivacyWorkflow privacy;
  late final FamilyRoutineController controller;
  late final FamilyPastimeController pastimeController;
  late final FamilyConversationTopicController conversationTopicController;
  late final FamilyMemoryController memoryController;
  late final FamilyObservationController observationController;
  late final SyncPresentationController syncController;
  late final PrivacyPresentationController privacyController;
  var _conflictSeq = 0;

  static const String demoSessionId = '01932f00-0006-7000-8000-000000000680';

  FakeSupabaseRemote? get fakeRemote =>
      transport is FakeSupabaseRemote ? transport as FakeSupabaseRemote : null;

  /// Seeds Demo/Ejemplo routines, memories, observations and demo session.
  ///
  /// Pastime fixtures are seeded only in isolated mode. Shared mode reconciles
  /// from the loopback authority so private rows cannot masquerade as remote.
  Future<void> seedDemoFixtures() async {
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await routines.save(
      routine: OfflineFixtures.archivedEveningRoutine,
      idempotencyKey: IdempotencyKey(
        'demo-routine-save-01932f00-0004-7000-8000-000000000401',
      ),
    );
    await reminders.save(
      reminder: OfflineFixtures.walkReminder,
      idempotencyKey: OfflineFixtures.walkReminderSaveKey,
    );
    await memories.save(
      memory: OfflineFixtures.gardenMemory,
      idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
    );
    await memories.save(
      memory: OfflineFixtures.proposedPatioMemory,
      idempotencyKey: IdempotencyKey(
        'demo-memory-save-01932f00-0005-7000-8000-000000000501',
      ),
    );
    await weights.append(
      observation: OfflineFixtures.amparoWeight,
      idempotencyKey: OfflineFixtures.weightAppendKey,
    );
    await bloodPressures.append(
      observation: OfflineFixtures.amparoBloodPressure,
      idempotencyKey: OfflineFixtures.bloodPressureAppendKey,
    );
    await LocalDemoSharedBootstrap.seedPastimeFixturesIfIsolated(
      pastimes: pastimes,
      sharedLocalDemo: usesSharedLocalDemoTransport,
    );
    await LocalDemoSharedBootstrap.seedConversationTopicFixturesIfIsolated(
      topics: conversationTopics,
      sharedLocalDemo: usesSharedLocalDemoTransport,
    );
    privacyStore.seedSession(
      SessionDescriptor(
        id: demoSessionId,
        userId: controller.actor.userId,
        familySpaceId: controller.actor.familySpaceId,
        label: 'demo-web',
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    );
  }

  /// Forces a concurrent routine edit conflict for demo/tests (fake remote).
  Future<void> forceRoutineConflict() async {
    final remote = fakeRemote;
    if (remote == null) {
      return;
    }
    final local = store.routineById(OfflineFixtures.morningRoutineId);
    if (local == null) {
      return;
    }
    remote.seed(
      aggregateType: OutboxAggregateType.routine,
      aggregateId: local.id.value,
      familySpaceId: local.familySpaceId.value,
      version: AggregateVersion(1),
      payload: {
        'title': 'Rutina remota Demo',
        'lifecycle': 'active',
        'steps': [
          {'order': 0, 'instruction': 'Paso remoto'},
        ],
        'tombstoned': false,
        'version': 1,
      },
    );
    store.putRoutine(
      local.copyWith(
        title: 'Rutina local Demo',
        version: AggregateVersion(1),
        syncState: SyncState.pending,
      ),
    );
    // Fresh outbox row so push works even after an earlier successful sync.
    await store.outbox.enqueue(
      OutboxOperation(
        idempotencyKey: IdempotencyKey(
          'demo-conflict-${OfflineFixtures.morningRoutineId.value}',
        ),
        aggregateType: OutboxAggregateType.routine,
        aggregateId: local.id.value,
        baseVersion: AggregateVersion.initial,
        enqueuedAt: DateTime.utc(2026, 10, 10, 12),
        state: SyncState.pending,
      ),
    );
  }

  MemoraFamilyWebApp buildApp({
    bool autoload = false,
    FeatureSection initialSection = FeatureSection.routines,
  }) {
    return MemoraFamilyWebApp(
      controller: controller,
      pastimeController: pastimeController,
      conversationTopicController: conversationTopicController,
      memoryController: memoryController,
      observationController: observationController,
      syncController: syncController,
      privacyController: privacyController,
      persona: SyntheticFixtures.familiaEjemplo,
      autoload: autoload,
      initialSection: initialSection,
      demoDataScope: usesSharedLocalDemoTransport
          ? DemoDataScope.sharedLocalDemo
          : DemoDataScope.isolatedLocal,
      enableQuietRemotePull: usesSharedLocalDemoTransport,
    );
  }

  /// Reconciles shared-demo pastimes from the authority before controllers load.
  Future<void> reconcileSharedDemoIfNeeded() async {
    if (!usesSharedLocalDemoTransport) {
      return;
    }
    final t = transport;
    try {
      if (t is LocalDemoSyncTransport) {
        await LocalDemoSharedBootstrap.reconcileFromAuthority(
          engine: engine,
          transport: t,
        );
      } else {
        await engine.pull(
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
      }
    } catch (_) {
      // Keep any local cache; pastime chrome surfaces pull failure on refresh.
    }
  }

  Future<void> load() async {
    await reconcileSharedDemoIfNeeded();
    await controller.load();
    await pastimeController.load();
    await conversationTopicController.load();
    await memoryController.load();
    conversationTopicController.setApprovedMemories(memoryController.memories);
    await observationController.load();
    await syncController.load();
    await privacyController.load();
  }
}
