import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Cross-process-equivalent pastime convergence: two independent stores,
/// one shared local demo HTTP transport (not a shared repository).
void main() {
  late LocalDemoSyncServer server;
  late LocalDemoSyncTransport caregiverTransport;
  late LocalDemoSyncTransport userTransport;

  setUp(() async {
    server = await LocalDemoSyncServer.bind(host: '127.0.0.1', port: 0);
    caregiverTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
    userTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
  });

  tearDown(() async {
    caregiverTransport.close();
    userTransport.close();
    await server.close();
  });

  test(
    'activate three pastimes from caregiver push/pull into independent user store',
    () async {
      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      final ids = <PastimeId>[
        OfflineFixtures.radioPastimeId,
        OfflineFixtures.draftPuzzlePastimeId,
        OfflineFixtures.archivedPhotosPastimeId,
      ];
      final titles = <String>[
        OfflineFixtures.radioPastime.title,
        'Puzzle Ejemplo',
        'Fotos Ejemplo',
      ];
      final instructions = <String>[
        OfflineFixtures.radioPastime.instruction,
        OfflineFixtures.draftPuzzlePastime.instruction,
        'Mirar el álbum familiar Demo con calma.',
      ];

      for (var i = 0; i < ids.length; i++) {
        await caregiver.configure.create(
          actor: elena,
          id: ids[i],
          familySpaceId: space,
          title: titles[i],
          instruction: instructions[i],
          lifecycleStatus: PastimeLifecycleStatus.active,
          displayOrder: i,
          idempotencyKey: IdempotencyKey('demo-cross-create-$i'),
        );
      }

      final push = await caregiver.engine.pushPending();
      expect(push.failed, 0);
      expect(push.conflicted, 0);
      expect(push.applied + push.duplicates, greaterThanOrEqualTo(3));

      final pull = await user.engine.pull(familySpaceId: space);
      expect(pull.applied, greaterThanOrEqualTo(3));

      final active = await user.configure.listActiveForViewing(
        actor: amparo,
        familySpaceId: space,
      );
      expect(active.map((p) => p.id), ids);
      expect(active.map((p) => p.title), titles);
    },
  );

  test(
    'archive and reorder on caregiver converge on independent user store',
    () async {
      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      final radio = OfflineFixtures.radioPastimeId;
      final puzzle = OfflineFixtures.draftPuzzlePastimeId;
      final photos = OfflineFixtures.archivedPhotosPastimeId;

      await caregiver.configure.create(
        actor: elena,
        id: radio,
        familySpaceId: space,
        title: 'Radio Demo',
        instruction: OfflineFixtures.radioPastime.instruction,
        lifecycleStatus: PastimeLifecycleStatus.active,
        displayOrder: 0,
        idempotencyKey: IdempotencyKey('demo-cross-a-create-0'),
      );
      await caregiver.configure.create(
        actor: elena,
        id: puzzle,
        familySpaceId: space,
        title: 'Puzzle Ejemplo',
        instruction: OfflineFixtures.draftPuzzlePastime.instruction,
        lifecycleStatus: PastimeLifecycleStatus.active,
        displayOrder: 1,
        idempotencyKey: IdempotencyKey('demo-cross-a-create-1'),
      );
      await caregiver.configure.create(
        actor: elena,
        id: photos,
        familySpaceId: space,
        title: 'Fotos Ejemplo',
        instruction: 'Mirar el álbum familiar Demo con calma.',
        lifecycleStatus: PastimeLifecycleStatus.active,
        displayOrder: 2,
        idempotencyKey: IdempotencyKey('demo-cross-a-create-2'),
      );

      await caregiver.engine.pushPending();
      await user.engine.pull(familySpaceId: space);

      await caregiver.configure.archive(
        actor: elena,
        id: photos,
        idempotencyKey: IdempotencyKey('demo-cross-archive-photos'),
      );
      await caregiver.configure.reorder(
        actor: elena,
        familySpaceId: space,
        orderedIds: [puzzle, radio, photos],
        idempotencyKey: IdempotencyKey('demo-cross-reorder'),
      );

      final push = await caregiver.engine.pushPending();
      expect(push.failed, 0);

      await user.engine.pull(familySpaceId: space);
      final active = await user.configure.listActiveForViewing(
        actor: amparo,
        familySpaceId: space,
      );
      expect(active.map((p) => p.id), [puzzle, radio]);
      expect(active.map((p) => p.displayOrder), [0, 1]);
    },
  );

  test('reset clears ephemeral shared authority for a fresh demo', () async {
    final caregiver = _ClientHarness(transport: caregiverTransport);
    final elena = IdentityFixtures.elenaPrimaryMembership;
    final space = IdentityFixtures.familiaEjemploSpaceId;

    await caregiver.configure.create(
      actor: elena,
      id: OfflineFixtures.radioPastimeId,
      familySpaceId: space,
      title: OfflineFixtures.radioPastime.title,
      instruction: OfflineFixtures.radioPastime.instruction,
      lifecycleStatus: PastimeLifecycleStatus.active,
      idempotencyKey: IdempotencyKey('demo-cross-reset-create'),
    );
    await caregiver.engine.pushPending();
    expect(
      (await caregiverTransport.pull(familySpaceId: space)).length,
      greaterThan(0),
    );

    // Ephemeral bind (no snapshot / baseline flag) clears to empty.
    await caregiverTransport.resetRemote();
    expect(await caregiverTransport.pull(familySpaceId: space), isEmpty);
  });
}

final class _ClientHarness {
  _ClientHarness({required SyncTransportPort transport})
    : store = InMemoryOfflineStore() {
    pastimes = InMemoryPastimeRepository(store);
    configure = ConfigurePastime(pastimes);
    bridge = OfflineSyncBridge(store);
    conflicts = InMemoryConflictStore();
    var conflictSeq = 0;
    engine = SyncEngine(
      outbox: store.outbox,
      transport: transport,
      conflicts: conflicts,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflictIdFactory: () {
        conflictSeq += 1;
        final suffix = conflictSeq.toString().padLeft(2, '0');
        return '01932f00-0008-7000-8000-000000000c$suffix';
      },
    );
  }

  final InMemoryOfflineStore store;
  late final InMemoryPastimeRepository pastimes;
  late final ConfigurePastime configure;
  late final OfflineSyncBridge bridge;
  late final InMemoryConflictStore conflicts;
  late final SyncEngine engine;
}
