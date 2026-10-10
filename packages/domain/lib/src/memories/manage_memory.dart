import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/memory_repository.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'memory_care_policy.dart';
import 'memory_entry.dart';
import 'memory_lifecycle_status.dart';
import 'memory_media_metadata.dart';

/// Caregiver/family memory use cases (manage + contribute + approved view).
final class ManageMemory {
  ManageMemory(this._memories);

  final MemoryRepository _memories;

  /// Manager creates an approved memory (or proposed when [asProposed] is true).
  Future<MemoryEntry> create({
    required FamilyMembership actor,
    required MemoryId id,
    required FamilySpaceId familySpaceId,
    required String caption,
    required String dateContext,
    required int displayOrder,
    required IdempotencyKey idempotencyKey,
    MemoryMediaMetadata? media,
    bool asProposed = false,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!MemoryCarePolicy.canManageMemories(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot manage memories',
      );
    }
    final memory = MemoryEntry(
      id: id,
      familySpaceId: familySpaceId,
      caption: caption,
      dateContext: dateContext,
      displayOrder: displayOrder,
      lifecycleStatus: asProposed
          ? MemoryLifecycleStatus.proposed
          : MemoryLifecycleStatus.approved,
      media: media,
      createdBy: actor.userId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _memories.save(memory: memory, idempotencyKey: idempotencyKey);
  }

  /// Family contributor proposes a memory (proposed lifecycle only).
  Future<MemoryEntry> contribute({
    required FamilyMembership actor,
    required MemoryId id,
    required FamilySpaceId familySpaceId,
    required String caption,
    required String dateContext,
    required int displayOrder,
    required IdempotencyKey idempotencyKey,
    MemoryMediaMetadata? media,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!MemoryCarePolicy.canContributeMemories(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot contribute memories',
      );
    }
    final memory = MemoryEntry(
      id: id,
      familySpaceId: familySpaceId,
      caption: caption,
      dateContext: dateContext,
      displayOrder: displayOrder,
      lifecycleStatus: MemoryLifecycleStatus.proposed,
      media: media,
      createdBy: actor.userId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _memories.save(memory: memory, idempotencyKey: idempotencyKey);
  }

  Future<MemoryEntry> edit({
    required FamilyMembership actor,
    required MemoryId id,
    required IdempotencyKey idempotencyKey,
    String? caption,
    String? dateContext,
    MemoryMediaMetadata? media,
    bool clearMedia = false,
  }) async {
    final current = await _requireMemory(id);
    _assertCanManage(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot edit deleted memory: ${id.value}');
    }
    final updated = current.copyWith(
      caption: caption,
      dateContext: dateContext,
      media: media,
      clearMedia: clearMedia,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _memories.save(memory: updated, idempotencyKey: idempotencyKey);
  }

  Future<MemoryEntry> reorder({
    required FamilyMembership actor,
    required MemoryId id,
    required int displayOrder,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireMemory(id);
    _assertCanManage(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot reorder deleted memory: ${id.value}');
    }
    final updated = current.copyWith(
      displayOrder: displayOrder,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _memories.save(memory: updated, idempotencyKey: idempotencyKey);
  }

  Future<MemoryEntry> approve({
    required FamilyMembership actor,
    required MemoryId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireMemory(id);
    _assertCanManage(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot approve deleted memory: ${id.value}');
    }
    if (current.lifecycleStatus != MemoryLifecycleStatus.proposed) {
      throw StateError(
        'only proposed memories can be approved: ${current.lifecycleStatus.wireName}',
      );
    }
    final updated = current.copyWith(
      lifecycleStatus: MemoryLifecycleStatus.approved,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _memories.save(memory: updated, idempotencyKey: idempotencyKey);
  }

  Future<MemoryEntry> archive({
    required FamilyMembership actor,
    required MemoryId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireMemory(id);
    _assertCanManage(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot archive deleted memory: ${id.value}');
    }
    final updated = current.copyWith(
      lifecycleStatus: MemoryLifecycleStatus.archived,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _memories.save(memory: updated, idempotencyKey: idempotencyKey);
  }

  /// Moves failed media upload state to pending for a retryable outbox sync.
  Future<MemoryEntry> retryFailedMedia({
    required FamilyMembership actor,
    required MemoryId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireMemory(id);
    _assertCanManage(actor, current.familySpaceId);
    final media = current.media;
    if (media == null) {
      throw StateError('memory has no media metadata: ${id.value}');
    }
    if (!media.isFailed) {
      throw StateError(
        'media uploadState is not failed: ${media.uploadState.name}',
      );
    }
    final updated = current.copyWith(
      media: media.copyWith(uploadState: SyncState.pending),
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _memories.save(memory: updated, idempotencyKey: idempotencyKey);
  }

  Future<List<MemoryEntry>> listApprovedForViewing({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!MemoryCarePolicy.canViewApprovedMemories(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot view approved memories',
      );
    }
    return _memories.listApprovedForFamily(familySpaceId);
  }

  void _assertCanManage(FamilyMembership actor, FamilySpaceId spaceId) {
    _assertSameSpace(actor, spaceId);
    if (!MemoryCarePolicy.canManageMemories(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot manage memories',
      );
    }
  }

  void _assertSameSpace(FamilyMembership actor, FamilySpaceId spaceId) {
    if (actor.familySpaceId != spaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${spaceId.value}',
      );
    }
  }

  Future<MemoryEntry> _requireMemory(MemoryId id) async {
    final current = await _memories.findById(id);
    if (current == null) {
      throw StateError('memory not found: ${id.value}');
    }
    return current;
  }
}
