import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';

/// Recorded blood-pressure observation. Values and metadata only.
///
/// Recording contract only — no clinical guidance helpers on this type.
/// Corrections append a new row linked via [correctsObservationId].
final class BloodPressureObservation {
  BloodPressureObservation({
    required this.id,
    required this.familySpaceId,
    required this.systolicMmHg,
    required this.diastolicMmHg,
    required this.recordedAt,
    required this.authorId,
    required this.version,
    required this.syncState,
    this.correctsObservationId,
    this.tombstone,
  }) {
    if (systolicMmHg <= 0) {
      throw ArgumentError.value(systolicMmHg, 'systolicMmHg', 'must be > 0');
    }
    if (diastolicMmHg <= 0) {
      throw ArgumentError.value(diastolicMmHg, 'diastolicMmHg', 'must be > 0');
    }
  }

  /// Plain unit label for storage/display. Not a clinical reference range.
  static const String unitLabel = 'mmHg';

  final ObservationId id;
  final FamilySpaceId familySpaceId;

  /// Systolic reading in mmHg. Storage only — not clinical guidance.
  final int systolicMmHg;

  /// Diastolic reading in mmHg. Storage only — not clinical guidance.
  final int diastolicMmHg;

  final DateTime recordedAt;
  final UserId authorId;

  /// When set, this row is an append-only correction of a prior observation.
  final ObservationId? correctsObservationId;

  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  bool get isCorrection => correctsObservationId != null;

  BloodPressureObservation copyWith({
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return BloodPressureObservation(
      id: id,
      familySpaceId: familySpaceId,
      systolicMmHg: systolicMmHg,
      diastolicMmHg: diastolicMmHg,
      recordedAt: recordedAt,
      authorId: authorId,
      correctsObservationId: correctsObservationId,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
