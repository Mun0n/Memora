import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'memory_lifecycle_status.dart';
import 'memory_media_metadata.dart';

/// Family memory entry with caption, date context and optional media metadata.
///
/// Local-first aggregate. Failed media never blocks caption/date navigation.
final class MemoryEntry {
  MemoryEntry({
    required this.id,
    required this.familySpaceId,
    required this.caption,
    required this.dateContext,
    required this.displayOrder,
    required this.lifecycleStatus,
    required this.version,
    required this.syncState,
    this.media,
    this.createdBy,
    this.tombstone,
  }) {
    if (caption.trim().isEmpty) {
      throw ArgumentError.value(caption, 'caption', 'must be non-empty');
    }
    if (dateContext.trim().isEmpty) {
      throw ArgumentError.value(
        dateContext,
        'dateContext',
        'must be non-empty',
      );
    }
    if (displayOrder < 0) {
      throw ArgumentError.value(displayOrder, 'displayOrder', 'must be >= 0');
    }
    if (media != null && media!.familySpaceId != familySpaceId) {
      throw ArgumentError.value(
        media!.familySpaceId.value,
        'media.familySpaceId',
        'must match memory family space',
      );
    }
  }

  final MemoryId id;
  final FamilySpaceId familySpaceId;
  final String caption;
  final String dateContext;
  final int displayOrder;
  final MemoryLifecycleStatus lifecycleStatus;
  final MemoryMediaMetadata? media;
  final UserId? createdBy;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Eligible for supported-person approved viewing (offline-cached content).
  bool get isApprovedForViewing =>
      !isDeleted && lifecycleStatus == MemoryLifecycleStatus.approved;

  /// Caption/date remain usable even when media upload failed.
  bool get hasFailedMedia => media?.isFailed ?? false;

  MemoryEntry copyWith({
    String? caption,
    String? dateContext,
    int? displayOrder,
    MemoryLifecycleStatus? lifecycleStatus,
    MemoryMediaMetadata? media,
    bool clearMedia = false,
    UserId? createdBy,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return MemoryEntry(
      id: id,
      familySpaceId: familySpaceId,
      caption: caption ?? this.caption,
      dateContext: dateContext ?? this.dateContext,
      displayOrder: displayOrder ?? this.displayOrder,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      media: clearMedia ? null : (media ?? this.media),
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
