import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../memories/memory_entry.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/conversation_topic_repository.dart';
import '../repositories/memory_repository.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'conversation_prompt.dart';
import 'conversation_topic.dart';
import 'conversation_topic_care_policy.dart';
import 'conversation_topic_lifecycle_status.dart';

/// Thrown when a prompt help memory reference is not approved / same-family.
final class InvalidConversationHelpMemoryException implements Exception {
  InvalidConversationHelpMemoryException(this.message, {this.promptOrder});

  final String message;
  final int? promptOrder;

  @override
  String toString() => 'InvalidConversationHelpMemoryException: $message';
}

/// Caregiver configure use cases for conversation topics.
///
/// Invalid field values throw before save so UI-held draft fields are preserved.
/// Activating (or saving as active) validates prompt-help memory references on
/// the authoritative memory boundary when a [MemoryRepository] is provided.
final class ConfigureConversationTopic {
  ConfigureConversationTopic(this._topics, {MemoryRepository? memories})
    : _memories = memories;

  final ConversationTopicRepository _topics;
  final MemoryRepository? _memories;

  Future<ConversationTopic> create({
    required FamilyMembership actor,
    required ConversationTopicId id,
    required FamilySpaceId familySpaceId,
    required String title,
    required String introduction,
    required List<ConversationPrompt> prompts,
    required String closing,
    required IdempotencyKey idempotencyKey,
    MemoryId? memoryId,
    ConversationTopicLifecycleStatus lifecycleStatus =
        ConversationTopicLifecycleStatus.draft,
    int? displayOrder,
  }) async {
    _assertCanEdit(actor, familySpaceId);
    if (lifecycleStatus == ConversationTopicLifecycleStatus.active) {
      await _assertActiveLimit(familySpaceId, excluding: null);
    }
    final order = displayOrder ?? await _nextDisplayOrder(familySpaceId);
    final topic = ConversationTopic(
      id: id,
      familySpaceId: familySpaceId,
      title: title,
      introduction: introduction,
      prompts: prompts,
      closing: closing,
      displayOrder: order,
      lifecycleStatus: lifecycleStatus,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
      memoryId: memoryId,
    );
    if (lifecycleStatus == ConversationTopicLifecycleStatus.active) {
      await assertPromptHelpMemoriesValid(topic);
    }
    return _topics.save(topic: topic, idempotencyKey: idempotencyKey);
  }

  Future<ConversationTopic> edit({
    required FamilyMembership actor,
    required ConversationTopicId id,
    required IdempotencyKey idempotencyKey,
    String? title,
    String? introduction,
    List<ConversationPrompt>? prompts,
    String? closing,
    MemoryId? memoryId,
    bool clearMemoryId = false,
  }) async {
    final current = await _requireTopic(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot edit deleted conversation topic: ${id.value}');
    }
    final updated = current.copyWith(
      title: title,
      introduction: introduction,
      prompts: prompts,
      closing: closing,
      memoryId: memoryId,
      clearMemoryId: clearMemoryId,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    if (updated.lifecycleStatus == ConversationTopicLifecycleStatus.active) {
      await assertPromptHelpMemoriesValid(updated);
    }
    return _topics.save(topic: updated, idempotencyKey: idempotencyKey);
  }

  /// Reassigns contiguous zero-based [ConversationTopic.displayOrder].
  Future<List<ConversationTopic>> reorder({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
    required List<ConversationTopicId> orderedIds,
    required IdempotencyKey idempotencyKey,
  }) async {
    _assertCanEdit(actor, familySpaceId);
    if (orderedIds.isEmpty) {
      throw ArgumentError.value(orderedIds, 'orderedIds', 'must be non-empty');
    }
    final existing = await _topics.listForFamily(familySpaceId);
    final live = existing.where((t) => !t.isDeleted).toList();
    if (orderedIds.length != live.length) {
      throw ArgumentError.value(
        orderedIds.map((id) => id.value).toList(),
        'orderedIds',
        'must include every non-deleted topic in the family exactly once',
      );
    }
    final byId = {for (final t in live) t.id.value: t};
    final result = <ConversationTopic>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final current = byId[id.value];
      if (current == null) {
        throw StateError('conversation topic not in family: ${id.value}');
      }
      final updated = current.copyWith(
        displayOrder: i,
        version: current.version.next(),
        syncState: SyncState.pending,
      );
      final key = IdempotencyKey('${idempotencyKey.value}#$i');
      result.add(await _topics.save(topic: updated, idempotencyKey: key));
    }
    return result;
  }

  Future<ConversationTopic> activate({
    required FamilyMembership actor,
    required ConversationTopicId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireTopic(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError(
        'cannot activate deleted conversation topic: ${id.value}',
      );
    }
    await assertPromptHelpMemoriesValid(current);
    if (current.lifecycleStatus != ConversationTopicLifecycleStatus.active) {
      await _assertActiveLimit(current.familySpaceId, excluding: current.id);
    }
    final updated = current.copyWith(
      lifecycleStatus: ConversationTopicLifecycleStatus.active,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _topics.save(topic: updated, idempotencyKey: idempotencyKey);
  }

  Future<ConversationTopic> archive({
    required FamilyMembership actor,
    required ConversationTopicId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireTopic(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError(
        'cannot archive deleted conversation topic: ${id.value}',
      );
    }
    final updated = current.copyWith(
      lifecycleStatus: ConversationTopicLifecycleStatus.archived,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _topics.save(topic: updated, idempotencyKey: idempotencyKey);
  }

  /// Active cached items for supported-person presentation, caregiver order.
  Future<List<ConversationTopic>> listActiveForViewing({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!ConversationTopicCarePolicy.canViewTopics(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot view conversation topics',
      );
    }
    return _topics.listActiveForFamily(familySpaceId);
  }

  /// Authoritative check: every prompt-help memory ref must exist, belong to
  /// the same family space, be approved, non-deleted and supported-visible.
  Future<void> assertPromptHelpMemoriesValid(ConversationTopic topic) async {
    for (final prompt in topic.prompts) {
      final help = prompt.help;
      if (help?.memoryId == null) {
        continue;
      }
      final memoryId = help!.memoryId!;
      final memories = _memories;
      if (memories == null) {
        throw InvalidConversationHelpMemoryException(
          'memory repository required to validate prompt help memory '
          '${memoryId.value}',
          promptOrder: prompt.order,
        );
      }
      final memory = await memories.findById(memoryId);
      if (!_isValidHelpMemory(memory, topic.familySpaceId, memoryId)) {
        throw InvalidConversationHelpMemoryException(
          'prompt help memory ${memoryId.value} must be approved, '
          'non-deleted and in family ${topic.familySpaceId.value}',
          promptOrder: prompt.order,
        );
      }
    }
  }

  static bool _isValidHelpMemory(
    MemoryEntry? memory,
    FamilySpaceId familySpaceId,
    MemoryId expectedId,
  ) {
    if (memory == null) {
      return false;
    }
    return memory.id == expectedId &&
        memory.familySpaceId == familySpaceId &&
        memory.isApprovedForViewing;
  }

  void _assertCanEdit(FamilyMembership actor, FamilySpaceId spaceId) {
    _assertSameSpace(actor, spaceId);
    if (!ConversationTopicCarePolicy.canEditTopics(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot edit conversation topics',
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

  Future<void> _assertActiveLimit(
    FamilySpaceId familySpaceId, {
    required ConversationTopicId? excluding,
  }) async {
    final active = await _topics.listActiveForFamily(familySpaceId);
    final count = active
        .where((t) => excluding == null || t.id != excluding)
        .length;
    if (count >= ConversationTopic.maxActivePerFamily) {
      throw StateError(
        'family already has ${ConversationTopic.maxActivePerFamily} '
        'active conversation topics',
      );
    }
  }

  Future<int> _nextDisplayOrder(FamilySpaceId familySpaceId) async {
    final listed = await _topics.listForFamily(familySpaceId);
    final live = listed.where((t) => !t.isDeleted);
    var max = -1;
    for (final t in live) {
      if (t.displayOrder > max) {
        max = t.displayOrder;
      }
    }
    return max + 1;
  }

  Future<ConversationTopic> _requireTopic(ConversationTopicId id) async {
    final current = await _topics.findById(id);
    if (current == null) {
      throw StateError('conversation topic not found: ${id.value}');
    }
    return current;
  }
}
