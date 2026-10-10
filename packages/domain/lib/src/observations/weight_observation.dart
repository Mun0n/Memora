import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';

/// Recorded weight observation. Values and metadata only.
///
/// Recording contract only — no clinical guidance helpers on this type.
/// Corrections append a new row linked via [correctsObservationId].
final class WeightObservation {
  WeightObservation({
    required this.id,
    required this.familySpaceId,
    required this.kilograms,
    required this.recordedAt,
    required this.authorId,
    required this.version,
    required this.syncState,
    this.correctsObservationId,
    this.tombstone,
  }) {
    if (kilograms <= 0 || !kilograms.isFinite) {
      throw ArgumentError.value(
        kilograms,
        'kilograms',
        'must be a finite number > 0',
      );
    }
  }

  /// Plain unit label for storage/display. Not a clinical reference range.
  static const String unitLabel = 'kg';

  final ObservationId id;
  final FamilySpaceId familySpaceId;

  /// Observed mass in kilograms. Storage only — not clinical guidance.
  final double kilograms;

  final DateTime recordedAt;
  final UserId authorId;

  /// When set, this row is an append-only correction of a prior observation.
  final ObservationId? correctsObservationId;

  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  bool get isCorrection => correctsObservationId != null;

  WeightObservation copyWith({
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return WeightObservation(
      id: id,
      familySpaceId: familySpaceId,
      kilograms: kilograms,
      recordedAt: recordedAt,
      authorId: authorId,
      correctsObservationId: correctsObservationId,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
