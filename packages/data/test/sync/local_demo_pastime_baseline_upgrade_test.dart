import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Slice 14 human-review Finding 1: obsolete Slice 8 Demo pastimes retire and
/// the three native-game baseline rows publish without touching other rows.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('memora_pastime_upgrade_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'pre-Slice-14 snapshot retires obsolete Demo IDs and publishes native games',
    () {
      final authority = InMemorySyncAuthority();
      for (final pastime in OfflineFixtures.obsoleteSlice8DemoPastimes) {
        authority.seed(
          aggregateType: OutboxAggregateType.pastime,
          aggregateId: pastime.id.value,
          familySpaceId: pastime.familySpaceId.value,
          version: AggregateVersion(1),
          payload: PastimeCodec.encodePayload(
            pastime.copyWith(version: AggregateVersion(1)),
          ),
        );
      }
      final caregiverCreated = Pastime(
        id: PastimeId('01932f00-0014-7000-8000-0000000014ff'),
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Paseo Ejemplo',
        instruction: 'Dar un paseo corto por el jardín Demo.',
        displayOrder: 3,
        lifecycleStatus: PastimeLifecycleStatus.active,
        version: AggregateVersion(1),
        syncState: SyncState.synced,
        experience: const GuidedPastimeExperience(),
      );
      authority.seed(
        aggregateType: OutboxAggregateType.pastime,
        aggregateId: caregiverCreated.id.value,
        familySpaceId: caregiverCreated.familySpaceId.value,
        version: AggregateVersion(1),
        payload: PastimeCodec.encodePayload(caregiverCreated),
      );

      expect(LocalDemoFictionalBaseline.ensurePastimes(authority), isTrue);
      expect(LocalDemoFictionalBaseline.ensurePastimes(authority), isFalse);

      for (final id in OfflineFixtures.obsoleteSlice8DemoPastimeIds) {
        final row = authority.recordFor(id.value)!;
        expect(row.tombstoned, isTrue);
        expect(row.version.value, greaterThanOrEqualTo(2));
      }

      final liveTitles =
          authority
              .pull(familySpaceId: IdentityFixtures.familiaEjemploSpaceId)
              .where(
                (r) =>
                    r.aggregateType == OutboxAggregateType.pastime &&
                    !r.tombstoned,
              )
              .map((r) => r.payload['title']! as String)
              .toList()
            ..sort();
      expect(liveTitles, [
        'Paseo Ejemplo',
        'Solitario Spider Demo',
        'Sopa de letras Demo',
        'Sudoku Demo',
      ]);

      final preserved = authority.recordFor(caregiverCreated.id.value)!;
      expect(preserved.tombstoned, isFalse);
      expect(preserved.payload['title'], 'Paseo Ejemplo');
      expect(preserved.version.value, 1);
    },
  );

  test(
    'durable restart upgrades obsolete snapshot; clients converge; idempotent',
    () async {
      final snapshotPath = '${tempDir.path}/authority_snapshot.json';
      final authority = InMemorySyncAuthority();
      for (final pastime in OfflineFixtures.obsoleteSlice8DemoPastimes) {
        authority.seed(
          aggregateType: OutboxAggregateType.pastime,
          aggregateId: pastime.id.value,
          familySpaceId: pastime.familySpaceId.value,
          version: AggregateVersion(1),
          payload: PastimeCodec.encodePayload(
            pastime.copyWith(version: AggregateVersion(1)),
          ),
        );
      }
      await File(snapshotPath).writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': LocalDemoFictionalBaseline.schemaVersion,
          'mode': 'local_fictional_demo',
          ...authority.exportSnapshot(),
        }),
      );

      final server = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server.close);

      for (final id in OfflineFixtures.obsoleteSlice8DemoPastimeIds) {
        expect(server.authority.isTombstoned(id.value), isTrue);
      }
      expect(await _activeBaselineTitles(server.baseUrl), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);

      final bootstrapTransport = LocalDemoSyncTransport(
        baseUrl: server.baseUrl,
      );
      addTearDown(bootstrapTransport.close);
      expect(await bootstrapTransport.ensureRemoteBaseline(), isFalse);

      final caregiver = _ClientHarness(
        transport: LocalDemoSyncTransport(baseUrl: server.baseUrl),
      );
      final user = _ClientHarness(
        transport: LocalDemoSyncTransport(baseUrl: server.baseUrl),
      );
      addTearDown(caregiver.transport.close);
      addTearDown(user.transport.close);

      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver.engine,
        transport: caregiver.transport,
      );
      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: user.engine,
        transport: user.transport,
      );

      final space = IdentityFixtures.familiaEjemploSpaceId;
      final caregiverListed = await caregiver.pastimes.listForFamily(space);
      final userActive = await user.configure.listActiveForViewing(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: space,
      );
      expect(caregiverListed.where((p) => !p.isDeleted).map((p) => p.title), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
      expect(userActive.map((p) => p.title), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
      expect(
        caregiverListed.any((p) => p.title == 'Radio Demo' && !p.isDeleted),
        isFalse,
      );

      // Second restart stays idempotent — no resurrection of obsolete cards.
      await server.close();
      final server2 = await LocalDemoSyncServer.bind(
        host: '127.0.0.1',
        port: 0,
        snapshotPath: snapshotPath,
        ensureFictionalBaselineWhenEmpty: true,
      );
      addTearDown(server2.close);
      expect(
        LocalDemoFictionalBaseline.ensurePastimes(server2.authority),
        isFalse,
      );
      expect(await _activeBaselineTitles(server2.baseUrl), [
        'Sudoku Demo',
        'Sopa de letras Demo',
        'Solitario Spider Demo',
      ]);
    },
  );
}

Future<List<String>> _activeBaselineTitles(String baseUrl) async {
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
                  !r.tombstoned,
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
  _ClientHarness({required this.transport}) : store = InMemoryOfflineStore() {
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
        return '01932f00-0014-7000-8000-000000000e$suffix';
      },
    );
  }

  final LocalDemoSyncTransport transport;
  final InMemoryOfflineStore store;
  late final InMemoryPastimeRepository pastimes;
  late final ConfigurePastime configure;
  late final OfflineSyncBridge bridge;
  late final InMemoryConflictStore conflicts;
  late final SyncEngine engine;
}
