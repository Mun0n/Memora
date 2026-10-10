import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryOfflineStore store;
  late FakeSupabaseRemote remote;
  late InMemoryConflictStore conflicts;
  late OfflineSyncBridge bridge;
  late SyncEngine engine;
  var conflictSeq = 0;

  SyncEngine buildEngine() {
    bridge = OfflineSyncBridge(store);
    return SyncEngine(
      outbox: store.outbox,
      transport: remote,
      conflicts: conflicts,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflictIdFactory: () {
        conflictSeq += 1;
        final suffix = conflictSeq.toString().padLeft(2, '0');
        return '01932f00-0006-7000-8000-0000000008$suffix';
      },
    );
  }

  setUp(() {
    store = InMemoryOfflineStore();
    remote = FakeSupabaseRemote();
    conflicts = InMemoryConflictStore();
    conflictSeq = 0;
    engine = buildEngine();
  });

  Future<Routine> seedLocalRoutine() async {
    final repo = InMemoryRoutineRepository(store);
    return repo.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
  }

  test('offline creation then push marks synced', () async {
    final saved = await seedLocalRoutine();
    expect(saved.syncState, SyncState.pending);

    final summary = await engine.pushPending();
    expect(summary.applied, 1);
    expect(summary.failed, 0);

    final after = store.routineById(OfflineFixtures.morningRoutineId)!;
    expect(after.syncState, SyncState.synced);
    expect(await store.outbox.listPending(), isEmpty);
  });

  test('restart restores outbox and completes push', () async {
    await seedLocalRoutine();
    final snapshot = store.capture();
    store = InMemoryOfflineStore.fromSnapshot(snapshot);
    engine = buildEngine();

    expect(await store.outbox.listPending(), hasLength(1));
    final summary = await engine.pushPending();
    expect(summary.applied, 1);
    expect(
      store.routineById(OfflineFixtures.morningRoutineId)!.syncState,
      SyncState.synced,
    );
  });

  test('retry moves failed to pending then succeeds', () async {
    await seedLocalRoutine();
    remote.failNextPush = true;
    var summary = await engine.pushPending();
    expect(summary.failed, 1);
    expect(
      store.routineById(OfflineFixtures.morningRoutineId)!.syncState,
      SyncState.failed,
    );

    summary = await engine.pushPending();
    expect(summary.applied, 1);
    expect(
      store.routineById(OfflineFixtures.morningRoutineId)!.syncState,
      SyncState.synced,
    );
  });

  test('duplicate delivery is ignored idempotently', () async {
    final op = OutboxOperation(
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      aggregateType: OutboxAggregateType.routine,
      aggregateId: OfflineFixtures.morningRoutineId.value,
      baseVersion: AggregateVersion.initial,
      enqueuedAt: DateTime.utc(2026, 10, 10),
      state: SyncState.pending,
    );
    final envelope = SyncEnvelope(
      operation: op,
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId.value,
      payload: {
        'title': OfflineFixtures.morningRoutine.title,
        'lifecycle': 'active',
        'steps': [
          {'order': 0, 'instruction': 'Beber un vaso de agua'},
          {'order': 1, 'instruction': 'Preparar el desayuno Ejemplo'},
        ],
        'tombstoned': false,
      },
    );

    final first = await remote.push(envelope);
    expect(first.outcome, PushOutcome.applied);

    final second = await remote.push(envelope);
    expect(second.outcome, PushOutcome.duplicateIgnored);
    expect(second.remoteVersion, first.remoteVersion);
  });

  test(
    'concurrent routine edit keeps both via conflict + resolve keepBoth',
    () async {
      final local = await seedLocalRoutine();
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

      final summary = await engine.pushPending();
      expect(summary.conflicted, greaterThanOrEqualTo(1));

      final unresolved = await conflicts.listUnresolved(local.familySpaceId);
      expect(unresolved, isNotEmpty);

      final resolved = await engine.resolveConflict(
        actor: IdentityFixtures.elenaPrimaryMembership,
        conflictId: unresolved.first.id,
        resolution: SyncConflictResolution.keepBoth,
      );
      expect(resolved.resolution, SyncConflictResolution.keepBoth);

      final routines = store.routinesForFamily(local.familySpaceId);
      expect(routines.length, greaterThanOrEqualTo(2));
    },
  );

  test('append-only observation conflict preserves local kilograms', () async {
    final observation = OfflineFixtures.amparoWeight;
    final repo = InMemoryWeightObservationRepository(store);
    await repo.append(
      observation: observation,
      idempotencyKey: OfflineFixtures.weightAppendKey,
    );

    remote.seed(
      aggregateType: OutboxAggregateType.weightObservation,
      aggregateId: observation.id.value,
      familySpaceId: observation.familySpaceId.value,
      version: AggregateVersion(1),
      payload: {
        'kilograms': 99.9,
        'recordedAt': observation.recordedAt.toUtc().toIso8601String(),
        'authorId': observation.authorId.value,
        'tombstoned': false,
        'version': 1,
      },
    );

    final summary = await engine.pushPending();
    expect(summary.conflicted, 1);

    final local = store.weightById(observation.id)!;
    expect(local.kilograms, observation.kilograms);
    expect(local.kilograms, isNot(99.9));
    expect(local.syncState, SyncState.conflicted);

    final conflict = (await conflicts.listUnresolved(
      observation.familySpaceId,
    )).single;
    expect(conflict.remotePayload['kilograms'], 99.9);
    expect(conflict.localPayload['kilograms'], observation.kilograms);
  });

  test('tombstone propagates on push and pull', () async {
    final saved = await seedLocalRoutine();
    await engine.pushPending();

    final repo = InMemoryRoutineRepository(store);
    await repo.softDelete(
      id: saved.id,
      baseVersion: store.routineById(saved.id)!.version,
      deletedAt: DateTime.utc(2026, 10, 10, 15),
      idempotencyKey: IdempotencyKey('demo-routine-tombstone-1'),
      deletedBy: IdentityFixtures.elenaPrimaryUserId,
    );
    await engine.pushPending();

    expect(store.routineById(saved.id)!.isDeleted, isTrue);
    expect(remote.isTombstoned(saved.id.value), isTrue);

    final pullStore = InMemoryOfflineStore();
    final pullBridge = OfflineSyncBridge(pullStore);
    final pullEngine = SyncEngine(
      outbox: pullStore.outbox,
      transport: remote,
      conflicts: InMemoryConflictStore(),
      payloadLoader: pullBridge,
      applyHandler: pullBridge,
      conflictIdFactory: () => '01932f00-0006-7000-8000-000000000899',
    );
    final pull = await pullEngine.pull(
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(pull.applied, greaterThan(0));
    expect(pullStore.routineById(saved.id)!.isDeleted, isTrue);
  });

  test('pull recovery applies remote routine into empty local store', () async {
    remote.seed(
      aggregateType: OutboxAggregateType.routine,
      aggregateId: OfflineFixtures.morningRoutineId.value,
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId.value,
      version: AggregateVersion(2),
      payload: {
        'title': 'Rutina recuperada Demo',
        'lifecycle': 'active',
        'steps': [
          {'order': 0, 'instruction': 'Recuperar paso'},
        ],
        'tombstoned': false,
        'version': 2,
      },
    );

    final pull = await engine.pull(
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(pull.applied, 1);
    final routine = store.routineById(OfflineFixtures.morningRoutineId)!;
    expect(routine.title, 'Rutina recuperada Demo');
    expect(routine.syncState, SyncState.synced);
  });
}
