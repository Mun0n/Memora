import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';

/// Recorded blood-pressure observation. Values and metadata only.
///
/// Recording contract only — no clinical guidance helpers on this type.
final class BloodPressureObservation {
  BloodPressureObservation({
    required this.id,
    required this.familySpaceId,
    required this.systolicMmHg,
    required this.diastolicMmHg,
    required this.recordedAt,
    required this.version,
    required this.syncState,
  }) {
    if (systolicMmHg <= 0) {
      throw ArgumentError.value(systolicMmHg, 'systolicMmHg', 'must be > 0');
    }
    if (diastolicMmHg <= 0) {
      throw ArgumentError.value(diastolicMmHg, 'diastolicMmHg', 'must be > 0');
    }
  }

  final ObservationId id;
  final FamilySpaceId familySpaceId;

  /// Systolic reading in mmHg. Storage only — not clinical guidance.
  final int systolicMmHg;

  /// Diastolic reading in mmHg. Storage only — not clinical guidance.
  final int diastolicMmHg;

  final DateTime recordedAt;
  final AggregateVersion version;
  final SyncState syncState;

  BloodPressureObservation copyWith({
    AggregateVersion? version,
    SyncState? syncState,
  }) {
    return BloodPressureObservation(
      id: id,
      familySpaceId: familySpaceId,
      systolicMmHg: systolicMmHg,
      diastolicMmHg: diastolicMmHg,
      recordedAt: recordedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
    );
  }
}
