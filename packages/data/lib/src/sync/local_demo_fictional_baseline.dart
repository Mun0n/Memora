import 'package:domain/domain.dart';

import 'conversation_topic_codec.dart';
import 'in_memory_sync_authority.dart';

/// Actionable failure when a durable local demo snapshot is unusable.
final class LocalDemoSyncSnapshotException implements Exception {
  LocalDemoSyncSnapshotException(this.message);

  final String message;

  @override
  String toString() => 'LocalDemoSyncSnapshotException: $message';
}

/// Single documented initializer for the shared local demo authority.
///
/// Publishes the deterministic Familia Ejemplo pastime and conversation-topic
/// baselines when those aggregates are missing for that fictional family space.
/// Independent clients must not each seed competing private fixtures in shared
/// mode.
abstract final class LocalDemoFictionalBaseline {
  static const int schemaVersion = 1;

  static FamilySpaceId get familySpaceId =>
      IdentityFixtures.familiaEjemploSpaceId;

  /// Ensures pastimes and conversation topics. Returns true if either published.
  static bool ensureBaseline(InMemorySyncAuthority authority) {
    final pastimes = ensurePastimes(authority);
    final topics = ensureConversationTopics(authority);
    return pastimes || topics;
  }

  /// Returns `true` when this call published the pastime baseline.
  static bool ensurePastimes(InMemorySyncAuthority authority) {
    if (authority.hasPastimeRowsFor(familySpaceId.value)) {
      return false;
    }
    _seedPastime(
      authority,
      pastime: OfflineFixtures.radioPastime,
      version: AggregateVersion(1),
    );
    _seedPastime(
      authority,
      pastime: OfflineFixtures.draftPuzzlePastime,
      version: AggregateVersion(1),
    );
    _seedPastime(
      authority,
      pastime: OfflineFixtures.archivedPhotosPastime,
      version: AggregateVersion(1),
    );
    return true;
  }

  /// Returns `true` when this call published the conversation-topic baseline.
  static bool ensureConversationTopics(InMemorySyncAuthority authority) {
    if (authority.hasConversationTopicRowsFor(familySpaceId.value)) {
      return false;
    }
    _seedTopic(
      authority,
      topic: OfflineFixtures.gardenTalkTopic,
      version: AggregateVersion(1),
    );
    _seedTopic(
      authority,
      topic: OfflineFixtures.draftKitchenTopic,
      version: AggregateVersion(1),
    );
    _seedTopic(
      authority,
      topic: OfflineFixtures.archivedMusicTopic,
      version: AggregateVersion(1),
    );
    return true;
  }

  static void _seedPastime(
    InMemorySyncAuthority authority, {
    required Pastime pastime,
    required AggregateVersion version,
  }) {
    authority.seed(
      aggregateType: OutboxAggregateType.pastime,
      aggregateId: pastime.id.value,
      familySpaceId: pastime.familySpaceId.value,
      version: version,
      payload: <String, Object?>{
        'title': pastime.title,
        'instruction': pastime.instruction,
        'displayOrder': pastime.displayOrder,
        'lifecycle': pastime.lifecycleStatus.wireName,
        'tombstoned': pastime.isDeleted,
        'version': version.value,
      },
      tombstoned: pastime.isDeleted,
    );
  }

  static void _seedTopic(
    InMemorySyncAuthority authority, {
    required ConversationTopic topic,
    required AggregateVersion version,
  }) {
    authority.seed(
      aggregateType: OutboxAggregateType.conversationTopic,
      aggregateId: topic.id.value,
      familySpaceId: topic.familySpaceId.value,
      version: version,
      payload: ConversationTopicCodec.encodePayload(
        topic.copyWith(version: version),
      ),
      tombstoned: topic.isDeleted,
    );
  }
}
