import 'package:domain/domain.dart';

/// Serializable capture of deterministic local state for restart simulation.
final class OfflineStoreSnapshot {
  const OfflineStoreSnapshot({
    required this.routines,
    required this.reminders,
    required this.memories,
    required this.weightObservations,
    required this.bloodPressureObservations,
    required this.outboxEntries,
  });

  final List<Routine> routines;
  final List<Reminder> reminders;
  final List<MemoryEntry> memories;
  final List<WeightObservation> weightObservations;
  final List<BloodPressureObservation> bloodPressureObservations;
  final List<OutboxOperation> outboxEntries;
}
