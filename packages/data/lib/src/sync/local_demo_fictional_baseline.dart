import 'package:domain/domain.dart';

import 'conversation_topic_codec.dart';
import 'in_memory_sync_authority.dart';
import 'pastime_codec.dart';
import 'supported_person_profile_codec.dart';

/// Actionable failure when a durable local demo snapshot is unusable.
final class LocalDemoSyncSnapshotException implements Exception {
  LocalDemoSyncSnapshotException(this.message);

  final String message;

  @override
  String toString() => 'LocalDemoSyncSnapshotException: $message';
}

/// Single documented initializer for the shared local demo authority.
///
/// Publishes the deterministic Familia Ejemplo pastime, conversation-topic and
/// preferred-name profile baselines when those aggregates are missing for that
/// fictional family space. Independent clients must not each seed competing
/// private fixtures in shared mode.
///
/// Slice 14 also retires the exact obsolete Slice 8 Demo pastime IDs via
/// tombstone and publishes the three native-game baseline rows. The upgrade is
/// idempotent and never mutates caregiver-created rows outside those IDs.
abstract final class LocalDemoFictionalBaseline {
  static const int schemaVersion = 1;

  static FamilySpaceId get familySpaceId =>
      IdentityFixtures.familiaEjemploSpaceId;

  /// Ensures pastimes, topics and preferred-name profile.
  ///
  /// Returns true if any aggregate published or upgraded.
  static bool ensureBaseline(InMemorySyncAuthority authority) {
    final pastimes = ensurePastimes(authority);
    final topics = ensureConversationTopics(authority);
    final profile = ensureSupportedPersonProfile(authority);
    return pastimes || topics || profile;
  }

  /// Returns `true` when this call retired obsolete Demo rows and/or published
  /// the Slice 14 native-game pastime baseline.
  static bool ensurePastimes(InMemorySyncAuthority authority) {
    final retired = _retireObsoleteSlice8DemoPastimes(authority);
    final published = _ensureNativeGamePastimes(authority);
    return retired || published;
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

  /// Returns `true` when this call published the preferred-name baseline.
  static bool ensureSupportedPersonProfile(InMemorySyncAuthority authority) {
    if (authority.hasSupportedPersonProfileRowsFor(familySpaceId.value)) {
      return false;
    }
    final profile = OfflineFixtures.amparoPreferredNameProfile;
    authority.seed(
      aggregateType: OutboxAggregateType.supportedPersonProfile,
      aggregateId: profile.id.value,
      familySpaceId: profile.familySpaceId.value,
      version: AggregateVersion(1),
      payload: SupportedPersonProfileCodec.encodePayload(
        profile.copyWith(version: AggregateVersion(1)),
      ),
      tombstoned: false,
    );
    return true;
  }

  /// Tombstones live obsolete Slice 8 Demo pastime rows for Familia Ejemplo.
  static bool _retireObsoleteSlice8DemoPastimes(
    InMemorySyncAuthority authority,
  ) {
    var changed = false;
    for (final pastime in OfflineFixtures.obsoleteSlice8DemoPastimes) {
      final existing = authority.recordFor(pastime.id.value);
      if (existing == null) {
        continue;
      }
      if (existing.familySpaceId != familySpaceId.value) {
        continue;
      }
      if (existing.aggregateType != OutboxAggregateType.pastime) {
        continue;
      }
      if (existing.tombstoned) {
        continue;
      }
      final nextVersion = AggregateVersion(existing.version.value + 1);
      final retired = pastime.copyWith(
        version: nextVersion,
        tombstone: Tombstone(
          aggregateId: pastime.id.value,
          version: nextVersion,
          deletedAt: DateTime.utc(2026, 10, 14, 12),
        ),
      );
      authority.seed(
        aggregateType: OutboxAggregateType.pastime,
        aggregateId: retired.id.value,
        familySpaceId: retired.familySpaceId.value,
        version: nextVersion,
        payload: PastimeCodec.encodePayload(retired),
        tombstoned: true,
      );
      changed = true;
    }
    return changed;
  }

  /// Publishes missing Slice 14 native-game baseline rows (never overwrites).
  static bool _ensureNativeGamePastimes(InMemorySyncAuthority authority) {
    var changed = false;
    for (final pastime in OfflineFixtures.slice14NativeDemoPastimes) {
      if (authority.recordFor(pastime.id.value) != null) {
        continue;
      }
      _seedPastime(authority, pastime: pastime, version: AggregateVersion(1));
      changed = true;
    }
    return changed;
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
      payload: PastimeCodec.encodePayload(pastime.copyWith(version: version)),
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
