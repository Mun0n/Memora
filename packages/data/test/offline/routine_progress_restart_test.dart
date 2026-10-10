import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'step complete/correct survives restart and enqueues idempotent outbox',
    () async {
      final live = InMemoryOfflineStore();
      final routines = InMemoryRoutineRepository(live);
      final progress = InMemoryRoutineProgressRepository(live);
      final record = RecordRoutineStepProgress(
        routines: routines,
        progress: progress,
      );

      await routines.save(
        routine: OfflineFixtures.morningRoutine,
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );

      final completed = await record.setStepStatus(
        actor: IdentityFixtures.amparoSupportedMembership,
        routineId: OfflineFixtures.morningRoutineId,
        localDate: OfflineFixtures.demoLocalDate,
        stepOrder: 0,
        status: StepCompletionStatus.completed,
        idempotencyKey: OfflineFixtures.morningProgressSaveKey,
        newProgressId: OfflineFixtures.morningProgressId,
      );
      expect(completed.stepAt(0).status, StepCompletionStatus.completed);

      // Idempotent re-submit of the same progress key does not duplicate outbox.
      await progress.save(
        progress: completed,
        idempotencyKey: OfflineFixtures.morningProgressSaveKey,
      );
      final progressPending = (await live.outbox.listPending())
          .where(
            (op) => op.aggregateType == OutboxAggregateType.routineProgress,
          )
          .toList(growable: false);
      expect(progressPending, hasLength(1));
      expect(
        progressPending.single.idempotencyKey,
        OfflineFixtures.morningProgressSaveKey,
      );

      final corrected = await record.setStepStatus(
        actor: IdentityFixtures.amparoSupportedMembership,
        routineId: OfflineFixtures.morningRoutineId,
        localDate: OfflineFixtures.demoLocalDate,
        stepOrder: 0,
        status: StepCompletionStatus.pending,
        idempotencyKey: IdempotencyKey('demo-progress-correct-restart'),
      );
      expect(corrected.stepAt(0).status, StepCompletionStatus.pending);

      final snapshot = live.capture();
      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredProgress = InMemoryRoutineProgressRepository(restored);
      final restoredRoutines = InMemoryRoutineRepository(restored);

      final routine = await restoredRoutines.findById(
        OfflineFixtures.morningRoutineId,
      );
      expect(routine, isNotNull);
      expect(routine!.isPresentableToday, isTrue);

      final day = await restoredProgress.findByRoutineAndDate(
        routineId: OfflineFixtures.morningRoutineId,
        localDate: OfflineFixtures.demoLocalDate,
      );
      expect(day, isNotNull);
      expect(day!.stepAt(0).status, StepCompletionStatus.pending);
      expect(day.syncState, SyncState.pending);

      final pendingKeys = (await restored.outbox.listPending())
          .map((op) => op.idempotencyKey.value)
          .toSet();
      expect(
        pendingKeys,
        contains(OfflineFixtures.morningProgressSaveKey.value),
      );
      expect(pendingKeys, contains('demo-progress-correct-restart'));
    },
  );

  test('archived routines are excluded from active family listing', () async {
    final store = InMemoryOfflineStore();
    final routines = InMemoryRoutineRepository(store);
    final configure = ConfigureRoutine(routines);

    await configure.create(
      actor: IdentityFixtures.elenaPrimaryMembership,
      id: OfflineFixtures.morningRoutineId,
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      title: OfflineFixtures.morningRoutine.title,
      steps: OfflineFixtures.morningRoutine.steps,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await configure.create(
      actor: IdentityFixtures.elenaPrimaryMembership,
      id: OfflineFixtures.archivedEveningRoutineId,
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      title: OfflineFixtures.archivedEveningRoutine.title,
      steps: OfflineFixtures.archivedEveningRoutine.steps,
      lifecycleStatus: RoutineLifecycleStatus.archived,
      idempotencyKey: IdempotencyKey('demo-archived-create'),
    );

    final active = await routines.listActiveForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(active, hasLength(1));
    expect(active.single.id, OfflineFixtures.morningRoutineId);

    final all = await routines.listForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(all, hasLength(2));
  });

  test('reminder quiet hours persist across restart snapshot', () async {
    final live = InMemoryOfflineStore();
    final reminders = InMemoryReminderRepository(live);
    await reminders.save(
      reminder: OfflineFixtures.walkReminder,
      idempotencyKey: OfflineFixtures.walkReminderSaveKey,
    );

    final restored = InMemoryOfflineStore.fromSnapshot(live.capture());
    final reminder = await InMemoryReminderRepository(
      restored,
    ).findById(OfflineFixtures.walkReminderId);
    expect(reminder, isNotNull);
    expect(reminder!.quietHours, isNotNull);
    expect(
      reminder.isConveniencePromptSuppressed(DateTime(2026, 10, 10, 23, 0)),
      isTrue,
    );
  });
}
