import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local conversation-topic repository. Immediate read-after-write.
final class InMemoryConversationTopicRepository
    implements ConversationTopicRepository {
  InMemoryConversationTopicRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<ConversationTopic> save({
    required ConversationTopic topic,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = topic.copyWith(syncState: SyncState.pending);
    _store.putConversationTopic(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.conversationTopic,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<ConversationTopic?> findById(ConversationTopicId id) async =>
      _store.conversationTopicById(id);

  @override
  Future<List<ConversationTopic>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.conversationTopicsForFamily(familySpaceId);
  }

  @override
  Future<List<ConversationTopic>> listActiveForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.activeConversationTopicsForFamily(familySpaceId);
  }

  @override
  Future<ConversationTopic> softDelete({
    required ConversationTopicId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.conversationTopicById(id);
    if (current == null) {
      throw StateError('conversation topic not found: ${id.value}');
    }
    final nextVersion = baseVersion.next();
    final deleted = current.copyWith(
      version: nextVersion,
      syncState: SyncState.pending,
      tombstone: Tombstone(
        aggregateId: id.value,
        version: nextVersion,
        deletedAt: deletedAt,
        deletedBy: deletedBy,
      ),
    );
    _store.putConversationTopic(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.conversationTopic,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
