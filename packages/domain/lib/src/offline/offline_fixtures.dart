import '../identity/identity_fixtures.dart';
import '../memories/memory_entry.dart';
import '../observations/blood_pressure_observation.dart';
import '../observations/weight_observation.dart';
import '../reminders/quiet_hours.dart';
import '../reminders/reminder.dart';
import '../routines/routine.dart';
import '../routines/routine_day_progress.dart';
import '../routines/routine_lifecycle_status.dart';
import '../routines/routine_step.dart';
import '../routines/routine_step_progress.dart';
import '../routines/step_completion_status.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'offline_identifiers.dart';

/// Stable Demo/Ejemplo offline fixtures for Slice 3–4 contracts.
///
/// Uses reserved Slice 2 family-space IDs. Values are fictional only.
abstract final class OfflineFixtures {
  static final RoutineId morningRoutineId = RoutineId(
    '01932f00-0003-7000-8000-000000000301',
  );

  static final RoutineId archivedEveningRoutineId = RoutineId(
    '01932f00-0004-7000-8000-000000000401',
  );

  static final ReminderId walkReminderId = ReminderId(
    '01932f00-0003-7000-8000-000000000302',
  );

  static final MemoryId gardenMemoryId = MemoryId(
    '01932f00-0003-7000-8000-000000000303',
  );

  static final ObservationId weightObservationId = ObservationId(
    '01932f00-0003-7000-8000-000000000304',
  );

  static final ObservationId bloodPressureObservationId = ObservationId(
    '01932f00-0003-7000-8000-000000000305',
  );

  static final RoutineProgressId morningProgressId = RoutineProgressId(
    '01932f00-0004-7000-8000-000000000402',
  );

  static final IdempotencyKey morningRoutineSaveKey = IdempotencyKey(
    'demo-routine-save-01932f00-0003-7000-8000-000000000301',
  );

  static final IdempotencyKey walkReminderSaveKey = IdempotencyKey(
    'demo-reminder-save-01932f00-0003-7000-8000-000000000302',
  );

  static final IdempotencyKey gardenMemorySaveKey = IdempotencyKey(
    'demo-memory-save-01932f00-0003-7000-8000-000000000303',
  );

  static final IdempotencyKey weightAppendKey = IdempotencyKey(
    'demo-weight-append-01932f00-0003-7000-8000-000000000304',
  );

  static final IdempotencyKey bloodPressureAppendKey = IdempotencyKey(
    'demo-bp-append-01932f00-0003-7000-8000-000000000305',
  );

  static final IdempotencyKey morningProgressSaveKey = IdempotencyKey(
    'demo-progress-save-01932f00-0004-7000-8000-000000000402',
  );

  static final DateTime demoRecordedAt = DateTime.utc(2026, 10, 10, 9, 0);

  /// Household-local civil date for "today" Demo progress proofs.
  static final DateTime demoLocalDate = DateTime(2026, 10, 10);

  /// Demo quiet hours 22:00–07:00 (overnight) — convenience suppression only.
  static final QuietHours demoQuietHours = QuietHours(
    startMinuteOfDay: 22 * 60,
    endMinuteOfDay: 7 * 60,
  );

  static final Routine morningRoutine = Routine(
    id: morningRoutineId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Rutina de mañana Demo',
    steps: <RoutineStep>[
      RoutineStep(order: 0, instruction: 'Beber un vaso de agua'),
      RoutineStep(order: 1, instruction: 'Preparar el desayuno Ejemplo'),
    ],
    lifecycleStatus: RoutineLifecycleStatus.active,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Archived Demo routine — excluded from today's active presentation.
  static final Routine archivedEveningRoutine = Routine(
    id: archivedEveningRoutineId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Rutina de tarde Ejemplo (archivada)',
    steps: <RoutineStep>[
      RoutineStep(order: 0, instruction: 'Poner la mesa Demo'),
    ],
    lifecycleStatus: RoutineLifecycleStatus.archived,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  static final Reminder walkReminder = Reminder(
    id: walkReminderId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Paseo corto Demo',
    scheduledAt: DateTime.utc(2026, 10, 10, 17, 30),
    quietHours: demoQuietHours,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  static final RoutineDayProgress morningProgressPending = RoutineDayProgress(
    id: morningProgressId,
    routineId: morningRoutineId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    localDate: demoLocalDate,
    steps: <RoutineStepProgress>[
      RoutineStepProgress(stepOrder: 0, status: StepCompletionStatus.pending),
      RoutineStepProgress(stepOrder: 1, status: StepCompletionStatus.pending),
    ],
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  static final MemoryEntry gardenMemory = MemoryEntry(
    id: gardenMemoryId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Jardín Ejemplo',
    body: 'Foto ficticia del jardín de Familia Ejemplo.',
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Fictional weight sample for Amparo Demo — observation storage only.
  static final WeightObservation amparoWeight = WeightObservation(
    id: weightObservationId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    kilograms: 62.5,
    recordedAt: demoRecordedAt,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Fictional blood-pressure sample — observation storage only.
  static final BloodPressureObservation amparoBloodPressure =
      BloodPressureObservation(
        id: bloodPressureObservationId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        systolicMmHg: 120,
        diastolicMmHg: 80,
        recordedAt: demoRecordedAt,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
}
