import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';

/// Family memory entry (text-only in this slice). Local-first aggregate.
final class MemoryEntry {
  MemoryEntry({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required this.body,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must be non-empty');
    }
    if (body.trim().isEmpty) {
      throw ArgumentError.value(body, 'body', 'must be non-empty');
    }
  }

  final MemoryId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final String body;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  MemoryEntry copyWith({
    String? title,
    String? body,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return MemoryEntry(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      body: body ?? this.body,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
