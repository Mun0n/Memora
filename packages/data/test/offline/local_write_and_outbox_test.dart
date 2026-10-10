import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryOfflineStore store;
  late InMemoryRoutineRepository routines;
  late InMemoryReminderRepository reminders;
  late InMemoryMemoryRepository memories;
  late InMemoryWeightObservationRepository weights;
  late InMemoryBloodPressureObservationRepository bloodPressures;

  setUp(() {
    store = InMemoryOfflineStore();
    routines = InMemoryRoutineRepository(store);
    reminders = InMemoryReminderRepository(store);
    memories = InMemoryMemoryRepository(store);
    weights = InMemoryWeightObservationRepository(store);
    bloodPressures = InMemoryBloodPressureObservationRepository(store);
  });

  test(
    'local writes are immediately readable and enqueue pending outbox',
    () async {
      final saved = await routines.save(
        routine: OfflineFixtures.morningRoutine,
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );

      final read = await routines.findById(OfflineFixtures.morningRoutineId);
      expect(read, isNotNull);
      expect(read!.title, OfflineFixtures.morningRoutine.title);
      expect(read.syncState, SyncState.pending);
      expect(saved.syncState, SyncState.pending);

      final pending = await store.outbox.listPending();
      expect(pending, hasLength(1));
      expect(
        pending.single.idempotencyKey,
        OfflineFixtures.morningRoutineSaveKey,
      );
      expect(pending.single.state, SyncState.pending);
      expect(
        pending.single.aggregateId,
        OfflineFixtures.morningRoutineId.value,
      );

      await reminders.save(
        reminder: OfflineFixtures.walkReminder,
        idempotencyKey: OfflineFixtures.walkReminderSaveKey,
      );
      await memories.save(
        memory: OfflineFixtures.gardenMemory,
        idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
      );
      await weights.append(
        observation: OfflineFixtures.amparoWeight,
        idempotencyKey: OfflineFixtures.weightAppendKey,
      );
      await bloodPressures.append(
        observation: OfflineFixtures.amparoBloodPressure,
        idempotencyKey: OfflineFixtures.bloodPressureAppendKey,
      );

      expect(
        await reminders.findById(OfflineFixtures.walkReminderId),
        isNotNull,
      );
      expect(
        await memories.findById(OfflineFixtures.gardenMemoryId),
        isNotNull,
      );
      expect(
        await weights.findById(OfflineFixtures.weightObservationId),
        isNotNull,
      );
      expect(
        await bloodPressures.findById(
          OfflineFixtures.bloodPressureObservationId,
        ),
        isNotNull,
      );
      expect(await store.outbox.listPending(), hasLength(5));
    },
  );

  test(
    'outbox enqueue is idempotent on repeated submit with same key',
    () async {
      await routines.save(
        routine: OfflineFixtures.morningRoutine,
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );
      await routines.save(
        routine: OfflineFixtures.morningRoutine.copyWith(title: 'Retry Demo'),
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );

      final pending = await store.outbox.listPending();
      expect(pending, hasLength(1));
      expect(
        pending.single.idempotencyKey,
        OfflineFixtures.morningRoutineSaveKey,
      );

      final again = await store.outbox.enqueue(
        OutboxOperation(
          idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
          aggregateType: OutboxAggregateType.routine,
          aggregateId: OfflineFixtures.morningRoutineId.value,
          baseVersion: AggregateVersion.initial,
          enqueuedAt: OfflineFixtures.demoRecordedAt,
          state: SyncState.pending,
        ),
      );
      expect(again.idempotencyKey, OfflineFixtures.morningRoutineSaveKey);
      expect(await store.outbox.listPending(), hasLength(1));
    },
  );

  test('append-only observations keep distinct rows without merging', () async {
    await weights.append(
      observation: OfflineFixtures.amparoWeight,
      idempotencyKey: OfflineFixtures.weightAppendKey,
    );
    final secondId = ObservationId('01932f00-0003-7000-8000-000000000306');
    await weights.append(
      observation: WeightObservation(
        id: secondId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        kilograms: 63.0,
        recordedAt: OfflineFixtures.demoRecordedAt.add(const Duration(days: 1)),
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      ),
      idempotencyKey: IdempotencyKey('demo-weight-append-second'),
    );

    final listed = await weights.listForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(listed, hasLength(2));
    expect(listed.map((o) => o.kilograms).toSet(), <double>{62.5, 63.0});
  });
}
