import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';

/// Timed reminder aggregate. Local-first; no delivery transport in this slice.
final class Reminder {
  Reminder({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required this.scheduledAt,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must be non-empty');
    }
  }

  final ReminderId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final DateTime scheduledAt;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  Reminder copyWith({
    String? title,
    DateTime? scheduledAt,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return Reminder(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
