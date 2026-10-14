import '../identity/identity_fixtures.dart';
import '../memories/memory_entry.dart';
import '../memories/memory_lifecycle_status.dart';
import '../memories/memory_media_metadata.dart';
import '../observations/blood_pressure_observation.dart';
import '../observations/weight_observation.dart';
import '../conversations/conversation_prompt.dart';
import '../conversations/conversation_prompt_help.dart';
import '../conversations/conversation_topic.dart';
import '../conversations/conversation_topic_lifecycle_status.dart';
import '../pastimes/pastime.dart';
import '../pastimes/pastime_lifecycle_status.dart';
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

/// Stable Demo/Ejemplo offline fixtures for Slice 3–10 contracts.
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

  static final MemoryId proposedPatioMemoryId = MemoryId(
    '01932f00-0005-7000-8000-000000000501',
  );

  static final ObservationId weightObservationId = ObservationId(
    '01932f00-0003-7000-8000-000000000304',
  );

  static final ObservationId bloodPressureObservationId = ObservationId(
    '01932f00-0003-7000-8000-000000000305',
  );

  static final ObservationId weightCorrectionId = ObservationId(
    '01932f00-0005-7000-8000-000000000504',
  );

  static final ObservationId bloodPressureCorrectionId = ObservationId(
    '01932f00-0005-7000-8000-000000000505',
  );

  static final RoutineProgressId morningProgressId = RoutineProgressId(
    '01932f00-0004-7000-8000-000000000402',
  );

  static final PastimeId radioPastimeId = PastimeId(
    '01932f00-0008-7000-8000-000000000801',
  );

  static final PastimeId draftPuzzlePastimeId = PastimeId(
    '01932f00-0008-7000-8000-000000000802',
  );

  static final PastimeId archivedPhotosPastimeId = PastimeId(
    '01932f00-0008-7000-8000-000000000803',
  );

  static final ConversationTopicId gardenTalkTopicId = ConversationTopicId(
    '01932f00-0010-7000-8000-000000001001',
  );

  static final ConversationTopicId draftKitchenTopicId = ConversationTopicId(
    '01932f00-0010-7000-8000-000000001002',
  );

  static final ConversationTopicId archivedMusicTopicId = ConversationTopicId(
    '01932f00-0010-7000-8000-000000001003',
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

  static final IdempotencyKey radioPastimeSaveKey = IdempotencyKey(
    'demo-pastime-save-01932f00-0008-7000-8000-000000000801',
  );

  static final IdempotencyKey gardenTalkTopicSaveKey = IdempotencyKey(
    'demo-topic-save-01932f00-0010-7000-8000-000000001001',
  );

  static final DateTime demoRecordedAt = DateTime.utc(2026, 10, 10, 9, 0);

  /// Household-local civil date for "today" Demo progress proofs.
  static final DateTime demoLocalDate = DateTime(2026, 10, 10);

  /// Demo quiet hours 22:00–07:00 (overnight) — convenience suppression only.
  static final QuietHours demoQuietHours = QuietHours(
    startMinuteOfDay: 22 * 60,
    endMinuteOfDay: 7 * 60,
  );

  /// Local fictional media path — not a production storage object.
  static final String gardenMediaPath =
      '${IdentityFixtures.familiaEjemploSpaceId.value}/memories/demo-jardin-ejemplo.jpg';

  static const String gardenMediaChecksum =
      'sha256:demo-fictional-checksum-jardin-ejemplo';

  static final MemoryMediaMetadata gardenMediaMetadata = MemoryMediaMetadata(
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    familyScopedPath: gardenMediaPath,
    checksum: gardenMediaChecksum,
    uploadState: SyncState.local,
  );

  static final MemoryMediaMetadata gardenMediaFailed = MemoryMediaMetadata(
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    familyScopedPath: gardenMediaPath,
    checksum: gardenMediaChecksum,
    uploadState: SyncState.failed,
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

  /// Approved Demo memory with fictional media metadata.
  static final MemoryEntry gardenMemory = MemoryEntry(
    id: gardenMemoryId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    caption: 'Jardín Ejemplo',
    dateContext: 'Octubre 2026 Demo',
    displayOrder: 0,
    lifecycleStatus: MemoryLifecycleStatus.approved,
    media: gardenMediaMetadata,
    createdBy: IdentityFixtures.elenaPrimaryUserId,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Proposed contributor memory — not visible to supported-person approved view.
  static final MemoryEntry proposedPatioMemory = MemoryEntry(
    id: proposedPatioMemoryId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    caption: 'Patio Ejemplo (propuesta)',
    dateContext: 'Septiembre 2026 Demo',
    displayOrder: 1,
    lifecycleStatus: MemoryLifecycleStatus.proposed,
    createdBy: IdentityFixtures.luciaContributorUserId,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Fictional weight sample for Amparo Demo — observation storage only.
  static final WeightObservation amparoWeight = WeightObservation(
    id: weightObservationId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    kilograms: 62.5,
    recordedAt: demoRecordedAt,
    authorId: IdentityFixtures.elenaPrimaryUserId,
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
        authorId: IdentityFixtures.elenaPrimaryUserId,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );

  /// Active Demo pastime for supported-person Pasatiempos presentation.
  static final Pastime radioPastime = Pastime(
    id: radioPastimeId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Radio Demo',
    instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
    displayOrder: 0,
    lifecycleStatus: PastimeLifecycleStatus.active,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Draft Demo pastime — never shown to the supported person.
  static final Pastime draftPuzzlePastime = Pastime(
    id: draftPuzzlePastimeId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Puzzle Ejemplo',
    instruction: 'Hacer un puzzle sencillo en la mesa Demo.',
    displayOrder: 1,
    lifecycleStatus: PastimeLifecycleStatus.draft,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Archived Demo pastime — excluded from supported-person view.
  static final Pastime archivedPhotosPastime = Pastime(
    id: archivedPhotosPastimeId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Fotos Ejemplo (archivado)',
    instruction: 'Mirar el álbum familiar Demo con calma.',
    displayOrder: 2,
    lifecycleStatus: PastimeLifecycleStatus.archived,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Active Demo conversation topic for supported-person Quiero hablar.
  ///
  /// Prompt 0 includes a cue-only help card (Slice 11). Prompt 1 stays without
  /// help so Slice 10 no-help behavior remains covered by the same fixture.
  static final ConversationTopic gardenTalkTopic = ConversationTopic(
    id: gardenTalkTopicId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'El jardín Demo',
    introduction:
        'Tu familia me ha contado que te gustaba cuidar el jardín Ejemplo.',
    prompts: <ConversationPrompt>[
      ConversationPrompt(
        order: 0,
        text:
            'Si te apetece, puedes contarme qué era lo que más te gustaba plantar.',
        help: ConversationPromptHelp(
          cue:
              'A Amparo Demo le gustaban los tomates del huerto Ejemplo '
              'por las mañanas.',
        ),
      ),
      ConversationPrompt(
        order: 1,
        text: 'Cuando quieras, habla un poco de las flores de la casa Demo.',
      ),
    ],
    closing: 'Gracias por compartir un rato. Podemos hablar otro día.',
    displayOrder: 0,
    lifecycleStatus: ConversationTopicLifecycleStatus.active,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
    memoryId: gardenMemoryId,
  );

  /// Draft Demo topic — never shown to the supported person.
  static final ConversationTopic draftKitchenTopic = ConversationTopic(
    id: draftKitchenTopicId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Cocina Ejemplo',
    introduction:
        'Tu familia recuerda las mañanas en la cocina Demo con calma.',
    prompts: <ConversationPrompt>[
      ConversationPrompt(
        order: 0,
        text: 'Si quieres, cuéntame un olor que te gustaba por la mañana.',
      ),
    ],
    closing: 'Cuando quieras, podemos dejarlo aquí.',
    displayOrder: 1,
    lifecycleStatus: ConversationTopicLifecycleStatus.draft,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );

  /// Archived Demo topic — excluded from supported-person view.
  static final ConversationTopic archivedMusicTopic = ConversationTopic(
    id: archivedMusicTopicId,
    familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    title: 'Música Ejemplo (archivado)',
    introduction:
        'Tu familia me ha contado que te gustaba escuchar música Demo.',
    prompts: <ConversationPrompt>[
      ConversationPrompt(
        order: 0,
        text: 'Si te apetece, habla de una canción que te gustaba.',
      ),
    ],
    closing: 'Podemos terminar cuando quieras.',
    displayOrder: 2,
    lifecycleStatus: ConversationTopicLifecycleStatus.archived,
    version: AggregateVersion.initial,
    syncState: SyncState.local,
  );
}
