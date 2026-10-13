import '../conversations/conversation_topic.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first conversation-topic port. Writes must be immediately readable.
abstract interface class ConversationTopicRepository {
  Future<ConversationTopic> save({
    required ConversationTopic topic,
    required IdempotencyKey idempotencyKey,
  });

  Future<ConversationTopic?> findById(ConversationTopicId id);

  Future<List<ConversationTopic>> listForFamily(FamilySpaceId familySpaceId);

  /// Active, non-tombstoned topics ordered by [ConversationTopic.displayOrder].
  Future<List<ConversationTopic>> listActiveForFamily(
    FamilySpaceId familySpaceId,
  );

  Future<ConversationTopic> softDelete({
    required ConversationTopicId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
