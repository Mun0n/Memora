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
  final Map<String, Reminder> _reminders = <String, Reminder>{};
  final Map<String, MemoryEntry> _memories = <String, MemoryEntry>{};
  final Map<String, WeightObservation> _weights = <String, WeightObservation>{};
  final Map<String, BloodPressureObservation> _bloodPressures =
      <String, BloodPressureObservation>{};

  OfflineStoreSnapshot capture() {
    return OfflineStoreSnapshot(
      routines: _routines.values.toList(growable: false),
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

  void putRoutine(Routine routine) {
    _routines[routine.id.value] = routine;
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
    return _memories.values
        .where((m) => m.familySpaceId == familySpaceId)
        .toList(growable: false);
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

  void putBloodPressure(BloodPressureObservation observation) {
    _bloodPressures[observation.id.value] = observation;
  }
}
