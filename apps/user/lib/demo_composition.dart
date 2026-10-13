import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

import 'android_local_speech_output.dart';
import 'android_on_device_speech_recognizer.dart';

/// Wires fictional in-memory adapters + demo sync transport for the user shell.
///
/// Default: private in-process [FakeSupabaseRemote] (isolated local demo).
/// With `--dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=...` (or [localDemoSyncUrl]):
/// [LocalDemoSyncTransport] against the shared loopback demo server.
///
/// Speech uses the real on-device adapters on Android. Tests and non-Android
/// demo hosts keep deterministic [FakeSpeechRecognizer] / [FakeSpeechOutput].
final class UserDemoComposition {
  UserDemoComposition({
    InMemoryOfflineStore? store,
    DateTime? clock,
    bool? networkAvailable,
    this.sessionBoundary = SessionBoundary.demo,
    SyncTransportPort? transport,
    FakeSupabaseRemote? remote,
    String? localDemoSyncUrl,
    bool? sharedLocalDemoTransport,
    SpeechRecognizerPort? speechRecognizer,
    SpeechOutputPort? speechOutput,
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
                   ))),
       speechRecognizer =
           speechRecognizer ??
           (AndroidOnDeviceSpeechRecognizer.isSupportedPlatform
               ? AndroidOnDeviceSpeechRecognizer()
               : FakeSpeechRecognizer()),
       speechOutput =
           speechOutput ??
           (AndroidLocalSpeechOutput.isSupportedPlatform
               ? AndroidLocalSpeechOutput()
               : FakeSpeechOutput()) {
    final resolvedNetwork = networkAvailable ?? usesSharedLocalDemoTransport;
    final scope = usesSharedLocalDemoTransport
        ? DemoDataScope.sharedLocalDemo
        : DemoDataScope.isolatedLocal;
    routines = InMemoryRoutineRepository(this.store);
    progress = InMemoryRoutineProgressRepository(this.store);
    pastimes = InMemoryPastimeRepository(this.store);
    conversationTopics = InMemoryConversationTopicRepository(this.store);
    memories = InMemoryMemoryRepository(this.store);
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
      networkAvailable: resolvedNetwork,
    );
    memoryController = UserMemoryController(
      actor: IdentityFixtures.amparoSupportedMembership,
      memories: memories,
      networkAvailable: resolvedNetwork,
    );
    pastimeController = UserPastimeController(
      actor: IdentityFixtures.amparoSupportedMembership,
      pastimes: pastimes,
      networkAvailable: resolvedNetwork,
      demoDataScope: scope,
    );
    conversationTopicController = UserConversationTopicController(
      actor: IdentityFixtures.amparoSupportedMembership,
      topics: conversationTopics,
      networkAvailable: resolvedNetwork,
      demoDataScope: scope,
      approvedMemoryLookup: () => memoryController.memories,
    );
    syncController = SyncPresentationController(
      actor: IdentityFixtures.amparoSupportedMembership,
      engine: engine,
      conflicts: conflicts,
      sessionBoundary: sessionBoundary,
    );
    pastimeController.quietRemotePull = syncController.quietPull;
    conversationTopicController.quietRemotePull = syncController.quietPull;
    privacyController = PrivacyPresentationController(
      actor: IdentityFixtures.amparoSupportedMembership,
      privacy: privacy,
      sessionBoundary: sessionBoundary,
      clock: DateTime.utc(2026, 10, 10, 9, 30),
    );
  }

  final InMemoryOfflineStore store;
  final SyncTransportPort transport;
  final bool usesSharedLocalDemoTransport;
  final SessionBoundary sessionBoundary;
  final SpeechRecognizerPort speechRecognizer;
  final SpeechOutputPort speechOutput;
  late final InMemoryRoutineRepository routines;
  late final InMemoryRoutineProgressRepository progress;
  late final InMemoryPastimeRepository pastimes;
  late final InMemoryConversationTopicRepository conversationTopics;
  late final InMemoryMemoryRepository memories;
  late final InMemoryConflictStore conflicts;
  late final InMemoryAuditStore audit;
  late final InMemoryPrivacyStore privacyStore;
  late final OfflineSyncBridge bridge;
  late final SyncEngine engine;
  late final PrivacyWorkflow privacy;
  late final UserRoutineController controller;
  late final UserMemoryController memoryController;
  late final UserPastimeController pastimeController;
  late final UserConversationTopicController conversationTopicController;
  late final SyncPresentationController syncController;
  late final PrivacyPresentationController privacyController;
  var _conflictSeq = 0;

  static const String demoSessionId = '01932f00-0006-7000-8000-000000000690';

  FakeSupabaseRemote? get fakeRemote =>
      transport is FakeSupabaseRemote ? transport as FakeSupabaseRemote : null;

  /// Seeds Demo/Ejemplo morning routine + approved garden memory + demo session.
  ///
  /// Pastime fixtures are seeded only in isolated mode. Shared mode reconciles
  /// from the loopback authority so private rows cannot masquerade as remote.
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
      pastimeController: pastimeController,
      conversationTopicController: conversationTopicController,
      syncController: syncController,
      privacyController: privacyController,
      speechRecognizer: speechRecognizer,
      speechOutput: speechOutput,
      persona: SyntheticFixtures.amparoDemo,
      autoload: autoload,
      initialDestination: initialDestination,
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
      // Keep any local cache; destination pull retains cache on failure.
    }
  }

  Future<void> load() async {
    await reconcileSharedDemoIfNeeded();
    await controller.load();
    await memoryController.load();
    await pastimeController.load();
    await conversationTopicController.load();
    await syncController.load();
    await privacyController.load();
  }
}
