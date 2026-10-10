import 'package:domain/domain.dart';

import 'in_memory_outbox.dart';
import 'offline_store_snapshot.dart';

/// Shared deterministic local store behind repository adapters.
///
/// Pure Dart maps only — Android Drift wiring is documented separately and must
/// not leak into domain ports.
final class InMemoryOfflineStore {
  InMemoryOfflineStore({InMemoryOutbox? outbox})
    : outbox = outbox ?? InMemoryOutbox();

  factory InMemoryOfflineStore.fromSnapshot(OfflineStoreSnapshot snapshot) {
    final store = InMemoryOfflineStore(
      outbox: InMemoryOutbox.fromEntries(snapshot.outboxEntries),
    );
    for (final routine in snapshot.routines) {
      store._routines[routine.id.value] = routine;
    }
    for (final progress in snapshot.routineProgress) {
      store._routineProgress[progress.id.value] = progress;
    }
    for (final reminder in snapshot.reminders) {
      store._reminders[reminder.id.value] = reminder;
    }
    for (final memory in snapshot.memories) {
      store._memories[memory.id.value] = memory;
    }
    for (final observation in snapshot.weightObservations) {
      store._weights[observation.id.value] = observation;
    }
    for (final observation in snapshot.bloodPressureObservations) {
      store._bloodPressures[observation.id.value] = observation;
    }
    return store;
  }

  final InMemoryOutbox outbox;

  final Map<String, Routine> _routines = <String, Routine>{};
  final Map<String, RoutineDayProgress> _routineProgress =
      <String, RoutineDayProgress>{};
  final Map<String, Reminder> _reminders = <String, Reminder>{};
  final Map<String, MemoryEntry> _memories = <String, MemoryEntry>{};
  final Map<String, WeightObservation> _weights = <String, WeightObservation>{};
  final Map<String, BloodPressureObservation> _bloodPressures =
      <String, BloodPressureObservation>{};

  OfflineStoreSnapshot capture() {
    return OfflineStoreSnapshot(
      routines: _routines.values.toList(growable: false),
      routineProgress: _routineProgress.values.toList(growable: false),
      reminders: _reminders.values.toList(growable: false),
      memories: _memories.values.toList(growable: false),
      weightObservations: _weights.values.toList(growable: false),
      bloodPressureObservations: _bloodPressures.values.toList(growable: false),
      outboxEntries: outbox.captureEntries(),
    );
  }

  Future<OutboxOperation> enqueueMutation({
    required IdempotencyKey idempotencyKey,
    required OutboxAggregateType aggregateType,
    required String aggregateId,
    required AggregateVersion baseVersion,
    required DateTime enqueuedAt,
  }) {
    return outbox.enqueue(
      OutboxOperation(
        idempotencyKey: idempotencyKey,
        aggregateType: aggregateType,
        aggregateId: aggregateId,
        baseVersion: baseVersion,
        enqueuedAt: enqueuedAt,
        state: SyncState.pending,
      ),
    );
  }

  // --- Routines ------------------------------------------------------------

  Routine? routineById(RoutineId id) => _routines[id.value];

  List<Routine> routinesForFamily(FamilySpaceId familySpaceId) {
    return _routines.values
        .where((r) => r.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  List<Routine> activeRoutinesForFamily(FamilySpaceId familySpaceId) {
    return _routines.values
        .where((r) => r.familySpaceId == familySpaceId && r.isPresentableToday)
        .toList(growable: false);
  }

  void putRoutine(Routine routine) {
    _routines[routine.id.value] = routine;
  }

  // --- Routine progress ----------------------------------------------------

  RoutineDayProgress? progressById(RoutineProgressId id) =>
      _routineProgress[id.value];

  RoutineDayProgress? progressByRoutineAndDate({
    required RoutineId routineId,
    required DateTime localDate,
  }) {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    for (final progress in _routineProgress.values) {
      if (progress.routineId == routineId &&
          progress.localDate == day &&
          !progress.isDeleted) {
        return progress;
      }
    }
    return null;
  }

  List<RoutineDayProgress> progressForFamily(FamilySpaceId familySpaceId) {
    return _routineProgress.values
        .where((p) => p.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  void putProgress(RoutineDayProgress progress) {
    _routineProgress[progress.id.value] = progress;
  }

  // --- Reminders -----------------------------------------------------------

  Reminder? reminderById(ReminderId id) => _reminders[id.value];

  List<Reminder> remindersForFamily(FamilySpaceId familySpaceId) {
    return _reminders.values
        .where((r) => r.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  void putReminder(Reminder reminder) {
    _reminders[reminder.id.value] = reminder;
  }

  // --- Memories ------------------------------------------------------------

  MemoryEntry? memoryById(MemoryId id) => _memories[id.value];

  List<MemoryEntry> memoriesForFamily(FamilySpaceId familySpaceId) {
    final listed = _memories.values
        .where((m) => m.familySpaceId == familySpaceId)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return List<MemoryEntry>.unmodifiable(listed);
  }

  List<MemoryEntry> approvedMemoriesForFamily(FamilySpaceId familySpaceId) {
    final listed = _memories.values
        .where(
          (m) => m.familySpaceId == familySpaceId && m.isApprovedForViewing,
        )
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return List<MemoryEntry>.unmodifiable(listed);
  }

  void putMemory(MemoryEntry memory) {
    _memories[memory.id.value] = memory;
  }

  // --- Observations --------------------------------------------------------

  WeightObservation? weightById(ObservationId id) => _weights[id.value];

  List<WeightObservation> weightsForFamily(FamilySpaceId familySpaceId) {
    return _weights.values
        .where((o) => o.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  List<WeightObservation> weightsChronological(FamilySpaceId familySpaceId) {
    final listed = weightsForFamily(familySpaceId).toList();
    listed.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List<WeightObservation>.unmodifiable(listed);
  }

  void putWeight(WeightObservation observation) {
    _weights[observation.id.value] = observation;
  }

  BloodPressureObservation? bloodPressureById(ObservationId id) =>
      _bloodPressures[id.value];

  List<BloodPressureObservation> bloodPressuresForFamily(
    FamilySpaceId familySpaceId,
  ) {
    return _bloodPressures.values
        .where((o) => o.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  List<BloodPressureObservation> bloodPressuresChronological(
    FamilySpaceId familySpaceId,
  ) {
    final listed = bloodPressuresForFamily(familySpaceId).toList();
    listed.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List<BloodPressureObservation>.unmodifiable(listed);
  }

  void putBloodPressure(BloodPressureObservation observation) {
    _bloodPressures[observation.id.value] = observation;
  }
}
