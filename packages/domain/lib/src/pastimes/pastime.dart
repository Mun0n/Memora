import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'pastime_lifecycle_status.dart';

/// Family-scoped pastime card with title, instruction and display order.
///
/// Local-first aggregate. No completion or performance claim is modeled.
final class Pastime {
  static const int maxTitleLength = 60;
  static const int maxInstructionLength = 240;
  static const int maxActivePerFamily = 6;

  Pastime({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required this.instruction,
    required this.displayOrder,
    required this.lifecycleStatus,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || trimmedTitle.length > maxTitleLength) {
      throw ArgumentError.value(
        title,
        'title',
        'must be 1–$maxTitleLength characters after trim',
      );
    }
    final trimmedInstruction = instruction.trim();
    if (trimmedInstruction.isEmpty ||
        trimmedInstruction.length > maxInstructionLength) {
      throw ArgumentError.value(
        instruction,
        'instruction',
        'must be 1–$maxInstructionLength characters after trim',
      );
    }
    if (displayOrder < 0) {
      throw ArgumentError.value(displayOrder, 'displayOrder', 'must be >= 0');
    }
  }

  final PastimeId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final String instruction;
  final int displayOrder;
  final PastimeLifecycleStatus lifecycleStatus;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Eligible for supported-person presentation (active, non-tombstoned).
  bool get isActiveForViewing =>
      !isDeleted && lifecycleStatus == PastimeLifecycleStatus.active;

  Pastime copyWith({
    String? title,
    String? instruction,
    int? displayOrder,
    PastimeLifecycleStatus? lifecycleStatus,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return Pastime(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      displayOrder: displayOrder ?? this.displayOrder,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
