import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'pastime_experience.dart';
import 'pastime_lifecycle_status.dart';

/// Family-scoped pastime card with title, instruction and display order.
///
/// Local-first aggregate. No completion or performance claim is modeled.
/// [experience] defaults to guided for Slice 8 compatibility.
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
    this.experience = PastimeExperience.guidedDefault,
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
  final PastimeExperience experience;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Lifecycle-active and not tombstoned (counts toward the six-active limit).
  bool get isLifecycleActive =>
      !isDeleted && lifecycleStatus == PastimeLifecycleStatus.active;

  /// Eligible for supported-person presentation (active, valid, non-tombstoned).
  ///
  /// Quarantined / incomplete experiences are excluded from the playable list
  /// while remaining visible to authorized caregivers via [listForFamily].
  bool get isActiveForViewing =>
      isLifecycleActive && experience.isCompleteAndSupported;

  /// Caregiver signal when an otherwise-active row cannot be opened safely.
  bool get isQuarantinedFromPlay =>
      isLifecycleActive && !experience.isCompleteAndSupported;

  Pastime copyWith({
    String? title,
    String? instruction,
    int? displayOrder,
    PastimeLifecycleStatus? lifecycleStatus,
    AggregateVersion? version,
    SyncState? syncState,
    PastimeExperience? experience,
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
      experience: experience ?? this.experience,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
