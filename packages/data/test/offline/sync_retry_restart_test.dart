import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('sync transitions cover pending → failed → retry → synced', () async {
    final store = InMemoryOfflineStore();
    final routines = InMemoryRoutineRepository(store);

    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );

    final key = OfflineFixtures.morningRoutineSaveKey;
    expect(
      (await store.outbox.findByIdempotencyKey(key))!.state,
      SyncState.pending,
    );

    final failed = await store.outbox.markFailed(key);
    expect(failed.state, SyncState.failed);
    expect(failed.attemptCount, 0);

    final retried = await store.outbox.retry(key);
    expect(retried.state, SyncState.pending);
    expect(retried.attemptCount, 1);

    final synced = await store.outbox.markSynced(key);
    expect(synced.state, SyncState.synced);

    expect(await store.outbox.listPending(), isEmpty);
    expect(await store.outbox.listRetryable(), isEmpty);
  });

  test('conflicted and local states remain first-class SyncState values', () {
    // Domain models expose all five states; outbox uses pending/failed/synced.
    expect(
      SyncState.values,
      containsAll(<SyncState>[
        SyncState.local,
        SyncState.pending,
        SyncState.synced,
        SyncState.conflicted,
        SyncState.failed,
      ]),
    );

    final conflicted = OfflineFixtures.morningRoutine.copyWith(
      syncState: SyncState.conflicted,
    );
    expect(conflicted.syncState, SyncState.conflicted);

    final localOnly = OfflineFixtures.gardenMemory;
    expect(localOnly.syncState, SyncState.local);
  });

  test(
    'restart simulation restores locals and pending outbox entries',
    () async {
      final live = InMemoryOfflineStore();
      final routines = InMemoryRoutineRepository(live);
      final weights = InMemoryWeightObservationRepository(live);

      await routines.save(
        routine: OfflineFixtures.morningRoutine,
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );
      await weights.append(
        observation: OfflineFixtures.amparoWeight,
        idempotencyKey: OfflineFixtures.weightAppendKey,
      );
      await live.outbox.markFailed(OfflineFixtures.weightAppendKey);

      final snapshot = live.capture();
      // Simulate process death: discard live store, rebuild from snapshot only.
      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredRoutines = InMemoryRoutineRepository(restored);
      final restoredWeights = InMemoryWeightObservationRepository(restored);

      final routine = await restoredRoutines.findById(
        OfflineFixtures.morningRoutineId,
      );
      expect(routine, isNotNull);
      expect(routine!.title, OfflineFixtures.morningRoutine.title);
      expect(routine.syncState, SyncState.pending);

      final weight = await restoredWeights.findById(
        OfflineFixtures.weightObservationId,
      );
      expect(weight, isNotNull);
      expect(weight!.kilograms, 62.5);

      final pending = await restored.outbox.listPending();
      expect(pending, hasLength(1));
      expect(
        pending.single.idempotencyKey,
        OfflineFixtures.morningRoutineSaveKey,
      );

      final retryable = await restored.outbox.listRetryable();
      expect(retryable, hasLength(2));
      expect(retryable.map((op) => op.state).toSet(), <SyncState>{
        SyncState.pending,
        SyncState.failed,
      });

      final retried = await restored.outbox.retry(
        OfflineFixtures.weightAppendKey,
      );
      expect(retried.state, SyncState.pending);
      expect(retried.attemptCount, 1);
    },
  );

  test('soft delete writes tombstone and pending outbox entry', () async {
    final store = InMemoryOfflineStore();
    final routines = InMemoryRoutineRepository(store);
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );

    final deleteKey = IdempotencyKey('demo-routine-delete-morning');
    final deleted = await routines.softDelete(
      id: OfflineFixtures.morningRoutineId,
      baseVersion: AggregateVersion.initial,
      deletedAt: OfflineFixtures.demoRecordedAt,
      idempotencyKey: deleteKey,
      deletedBy: IdentityFixtures.elenaPrimaryUserId,
    );

    expect(deleted.isDeleted, isTrue);
    expect(deleted.tombstone!.deletedBy, IdentityFixtures.elenaPrimaryUserId);
    expect(deleted.version.value, 1);

    final entry = await store.outbox.findByIdempotencyKey(deleteKey);
    expect(entry, isNotNull);
    expect(entry!.state, SyncState.pending);
    expect(entry.baseVersion, AggregateVersion.initial);
  });
}
