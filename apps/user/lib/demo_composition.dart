import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// Wires fictional in-memory adapters + fake remote for supported-person shell.
final class UserDemoComposition {
  UserDemoComposition({
    InMemoryOfflineStore? store,
    DateTime? clock,
    bool networkAvailable = false,
    this.sessionBoundary = SessionBoundary.demo,
    FakeSupabaseRemote? remote,
  }) : store = store ?? InMemoryOfflineStore(),
       remote = remote ?? FakeSupabaseRemote() {
    routines = InMemoryRoutineRepository(this.store);
    progress = InMemoryRoutineProgressRepository(this.store);
    memories = InMemoryMemoryRepository(this.store);
    conflicts = InMemoryConflictStore();
    audit = InMemoryAuditStore();
    privacyStore = InMemoryPrivacyStore();
    bridge = OfflineSyncBridge(this.store);
    engine = SyncEngine(
      outbox: this.store.outbox,
      transport: this.remote,
      conflicts: conflicts,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflictIdFactory: () {
        _conflictSeq += 1;
        final suffix = _conflictSeq.toString().padLeft(2, '0');
        return '01932f00-0006-7000-8000-000000000a$suffix';
      },
    );
    privacy = PrivacyWorkflow(audit: audit, store: privacyStore);
    controller = UserRoutineController(
      actor: IdentityFixtures.amparoSupportedMembership,
      routines: routines,
      progress: progress,
      localDate: OfflineFixtures.demoLocalDate,
      clock: clock ?? DateTime(2026, 10, 10, 9, 30),
      networkAvailable: networkAvailable,
    );
    memoryController = UserMemoryController(
      actor: IdentityFixtures.amparoSupportedMembership,
      memories: memories,
      networkAvailable: networkAvailable,
    );
    syncController = SyncPresentationController(
      actor: IdentityFixtures.amparoSupportedMembership,
      engine: engine,
      conflicts: conflicts,
      sessionBoundary: sessionBoundary,
    );
    privacyController = PrivacyPresentationController(
      actor: IdentityFixtures.amparoSupportedMembership,
      privacy: privacy,
      sessionBoundary: sessionBoundary,
      clock: DateTime.utc(2026, 10, 10, 9, 30),
    );
  }

  final InMemoryOfflineStore store;
  final FakeSupabaseRemote remote;
  final SessionBoundary sessionBoundary;
  late final InMemoryRoutineRepository routines;
  late final InMemoryRoutineProgressRepository progress;
  late final InMemoryMemoryRepository memories;
  late final InMemoryConflictStore conflicts;
  late final InMemoryAuditStore audit;
  late final InMemoryPrivacyStore privacyStore;
  late final OfflineSyncBridge bridge;
  late final SyncEngine engine;
  late final PrivacyWorkflow privacy;
  late final UserRoutineController controller;
  late final UserMemoryController memoryController;
  late final SyncPresentationController syncController;
  late final PrivacyPresentationController privacyController;
  var _conflictSeq = 0;

  static const String demoSessionId = '01932f00-0006-7000-8000-000000000690';

  /// Seeds Demo/Ejemplo morning routine + approved garden memory + demo session.
  Future<void> seedDemoFixtures() async {
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await progress.save(
      progress: OfflineFixtures.morningProgressPending,
      idempotencyKey: OfflineFixtures.morningProgressSaveKey,
    );
    await memories.save(
      memory: OfflineFixtures.gardenMemory,
      idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
    );
    // Proposed memory must not appear in approved viewing.
    await memories.save(
      memory: OfflineFixtures.proposedPatioMemory,
      idempotencyKey: IdempotencyKey(
        'demo-memory-save-01932f00-0005-7000-8000-000000000501',
      ),
    );
    privacyStore.seedSession(
      SessionDescriptor(
        id: demoSessionId,
        userId: IdentityFixtures.amparoSupportedUserId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        label: 'demo-tablet',
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    );
  }

  MemoraUserApp buildApp({
    bool autoload = false,
    UserHomeDestination initialDestination = UserHomeDestination.home,
  }) {
    return MemoraUserApp(
      controller: controller,
      memoryController: memoryController,
      syncController: syncController,
      privacyController: privacyController,
      persona: SyntheticFixtures.amparoDemo,
      autoload: autoload,
      initialDestination: initialDestination,
    );
  }

  Future<void> load() async {
    await controller.load();
    await memoryController.load();
    await syncController.load();
    await privacyController.load();
  }
}
