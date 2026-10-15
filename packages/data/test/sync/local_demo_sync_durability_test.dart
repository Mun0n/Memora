import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Production-like shared demo: real loopback HTTP server, two independent
/// stores (caregiver + supported-person harnesses), durable snapshot, single
/// baseline initializer. Does not use [FakeSupabaseRemote].
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('memora_demo_sync_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'empty authority initializes baseline once; clients pull without local seed',
    () async {
      final snapshotPath = '${tempDir.path}/authority_snapshot.json';
      final server = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server.close);

      expect(server.isDurable, isTrue);
      expect(File(snapshotPath).existsSync(), isTrue);
      expect(
        server.authority.hasPastimeRowsFor(
          IdentityFixtures.familiaEjemploSpaceId.value,
        ),
        isTrue,
      );

      final caregiverTransport = LocalDemoSyncTransport(
        baseUrl: server.baseUrl,
      );
      final userTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
      addTearDown(caregiverTransport.close);
      addTearDown(userTransport.close);

      // Second bootstrap is a no-op (single initializer).
      expect(await caregiverTransport.ensureRemoteBaseline(), isFalse);

      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final space = IdentityFixtures.familiaEjemploSpaceId;

      await LocalDemoSharedBootstrap.seedPastimeFixturesIfIsolated(
        pastimes: caregiver.pastimes,
        sharedLocalDemo: true,
      );
      await LocalDemoSharedBootstrap.seedPastimeFixturesIfIsolated(
        pastimes: user.pastimes,
        sharedLocalDemo: true,
      );
      expect(await caregiver.pastimes.listForFamily(space), isEmpty);
      expect(await user.pastimes.listForFamily(space), isEmpty);

      final caregiverPull =
          await LocalDemoSharedBootstrap.reconcileFromAuthority(
            engine: caregiver.engine,
            transport: caregiverTransport,
          );
      final userPull = await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: user.engine,
        transport: userTransport,
      );
      expect(caregiverPull.applied, greaterThanOrEqualTo(3));
      expect(userPull.applied, greaterThanOrEqualTo(3));

      final caregiverListed = await caregiver.pastimes.listForFamily(space);
      final userActive = await user.configure.listActiveForViewing(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: space,
      );
      expect(caregiverListed.map((p) => p.title), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
      expect(userActive.map((p) => p.title), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
      expect(userActive[0].experience, isA<SudokuPastimeExperience>());
      expect(userActive[1].experience, isA<WordSearchPastimeExperience>());
      expect(userActive[2].experience, isA<SpiderSolitairePastimeExperience>());
    },
  );

  test(
    'caregiver reorder converges on user pull over durable HTTP authority',
    () async {
      final snapshotPath = '${tempDir.path}/authority_snapshot.json';
      final server = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server.close);

      final caregiverTransport = LocalDemoSyncTransport(
        baseUrl: server.baseUrl,
      );
      final userTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
      addTearDown(caregiverTransport.close);
      addTearDown(userTransport.close);

      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver.engine,
        transport: caregiverTransport,
      );

      final sudoku = OfflineFixtures.sudokuDemoPastimeId;
      final words = OfflineFixtures.wordSearchDemoPastimeId;
      final spider = OfflineFixtures.spiderSolitaireDemoPastimeId;

      await caregiver.configure.reorder(
        actor: elena,
        familySpaceId: space,
        orderedIds: [spider, sudoku, words],
        idempotencyKey: IdempotencyKey('demo-durable-reorder'),
      );

      final push = await caregiver.engine.pushPending();
      expect(push.failed, 0);
      expect(push.conflicted, 0);

      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: user.engine,
        transport: userTransport,
      );
      final active = await user.configure.listActiveForViewing(
        actor: amparo,
        familySpaceId: space,
      );
      expect(active.map((p) => p.id), [spider, sudoku, words]);
      expect(active.map((p) => p.displayOrder), [0, 1, 2]);
    },
  );

  test(
    'authority restart keeps caregiver configuration; fresh clients load snapshot',
    () async {
      final snapshotPath = '${tempDir.path}/authority_snapshot.json';
      final server1 = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      final transport1 = LocalDemoSyncTransport(baseUrl: server1.baseUrl);
      final caregiver1 = _ClientHarness(transport: transport1);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver1.engine,
        transport: transport1,
      );
      await caregiver1.configure.reorder(
        actor: elena,
        familySpaceId: space,
        orderedIds: [
          OfflineFixtures.wordSearchDemoPastimeId,
          OfflineFixtures.sudokuDemoPastimeId,
          OfflineFixtures.spiderSolitaireDemoPastimeId,
        ],
        idempotencyKey: IdempotencyKey('demo-restart-reorder'),
      );
      final push = await caregiver1.engine.pushPending();
      expect(push.failed, 0);
      transport1.close();
      await server1.close();

      // Restart authority from the same durable snapshot (no reseeding defaults).
      final server2 = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server2.close);
      expect(await transportBaselineActiveTitles(server2.baseUrl), [
        'Sopa de letras Demo',
        'Sudoku Demo',
        'Solitario Spider Demo',
      ]);

      final caregiverTransport = LocalDemoSyncTransport(
        baseUrl: server2.baseUrl,
      );
      final userTransport = LocalDemoSyncTransport(baseUrl: server2.baseUrl);
      addTearDown(caregiverTransport.close);
      addTearDown(userTransport.close);

      final caregiver2 = _ClientHarness(transport: caregiverTransport);
      final user2 = _ClientHarness(transport: userTransport);
      await LocalDemoSharedBootstrap.seedPastimeFixturesIfIsolated(
        pastimes: caregiver2.pastimes,
        sharedLocalDemo: true,
      );
      await LocalDemoSharedBootstrap.seedPastimeFixturesIfIsolated(
        pastimes: user2.pastimes,
        sharedLocalDemo: true,
      );

      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver2.engine,
        transport: caregiverTransport,
      );
      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: user2.engine,
        transport: userTransport,
      );

      final active = await user2.configure.listActiveForViewing(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: space,
      );
      expect(active.map((p) => p.title), [
        'Sopa de letras Demo',
        'Sudoku Demo',
        'Solitario Spider Demo',
      ]);
      expect(active.map((p) => p.displayOrder), [0, 1, 2]);
    },
  );

  test('corrupt snapshot fails with actionable local demo error', () async {
    final snapshotPath = '${tempDir.path}/authority_snapshot.json';
    await File(
      snapshotPath,
    ).writeAsString('{"schemaVersion":999,"mode":"nope"}');
    await expectLater(
      LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      ),
      throwsA(
        isA<LocalDemoSyncSnapshotException>().having(
          (e) => e.message,
          'message',
          contains('incompatible local demo snapshot'),
        ),
      ),
    );
  });

  test(
    'reset restores fictional pastime baseline on durable authority',
    () async {
      final snapshotPath = '${tempDir.path}/authority_snapshot.json';
      final server = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server.close);
      final transport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
      addTearDown(transport.close);

      final caregiver = _ClientHarness(transport: transport);
      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver.engine,
        transport: transport,
      );
      await caregiver.configure.archive(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.spiderSolitaireDemoPastimeId,
        idempotencyKey: IdempotencyKey('demo-reset-archive'),
      );
      await caregiver.engine.pushPending();

      await transport.resetRemote();
      final records = await transport.pull(
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );
      final pastimes = records
          .where(
            (r) =>
                r.aggregateType == OutboxAggregateType.pastime && !r.tombstoned,
          )
          .toList();
      expect(pastimes, hasLength(3));
      expect(pastimes.map((r) => r.aggregateId).toSet(), {
        OfflineFixtures.sudokuDemoPastimeId.value,
        OfflineFixtures.wordSearchDemoPastimeId.value,
        OfflineFixtures.spiderSolitaireDemoPastimeId.value,
      });
      for (final row in pastimes) {
        expect(row.payload['lifecycle'], 'active');
      }
      expect(await transportBaselineActiveTitles(server.baseUrl), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
    },
  );
}

Future<List<String>> transportBaselineActiveTitles(String baseUrl) async {
  final transport = LocalDemoSyncTransport(baseUrl: baseUrl);
  try {
    final records = await transport.pull(
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    );
    final active =
        records
            .where(
              (r) =>
                  r.aggregateType == OutboxAggregateType.pastime &&
                  r.payload['lifecycle'] == 'active' &&
                  r.tombstoned == false,
            )
            .toList()
          ..sort(
            (a, b) => ((a.payload['displayOrder'] as int?) ?? 0).compareTo(
              (b.payload['displayOrder'] as int?) ?? 0,
            ),
          );
    return active.map((r) => r.payload['title']! as String).toList();
  } finally {
    transport.close();
  }
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
        return '01932f00-0008-7000-8000-000000000d$suffix';
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
