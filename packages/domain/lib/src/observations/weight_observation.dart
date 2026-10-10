import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';

/// Recorded weight observation. Values and metadata only.
///
/// Recording contract only — no clinical guidance helpers on this type.
final class WeightObservation {
  WeightObservation({
    required this.id,
    required this.familySpaceId,
    required this.kilograms,
    required this.recordedAt,
    required this.version,
    required this.syncState,
  }) {
    if (kilograms <= 0 || !kilograms.isFinite) {
      throw ArgumentError.value(
        kilograms,
        'kilograms',
        'must be a finite number > 0',
      );
    }
  }

  final ObservationId id;
  final FamilySpaceId familySpaceId;

  /// Observed mass in kilograms. Storage only — not clinical guidance.
  final double kilograms;

  final DateTime recordedAt;
  final AggregateVersion version;
  final SyncState syncState;

  WeightObservation copyWith({
    AggregateVersion? version,
    SyncState? syncState,
  }) {
    return WeightObservation(
      id: id,
      familySpaceId: familySpaceId,
      kilograms: kilograms,
      recordedAt: recordedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
    );
  }
}
