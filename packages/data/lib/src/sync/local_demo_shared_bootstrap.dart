import 'package:domain/domain.dart';

import '../offline/in_memory_conversation_topic_repository.dart';
import '../offline/in_memory_pastime_repository.dart';
import 'local_demo_fictional_baseline.dart';
import 'local_demo_sync_transport.dart';

/// Shared-demo bootstrap helpers for separately running clients.
///
/// Source of truth is the loopback authority. Isolated demos may keep private
/// fixtures; shared mode must reconcile from the authority and must not seed
/// competing local rows that masquerade as remote data.
abstract final class LocalDemoSharedBootstrap {
  /// Seeds the deterministic pastime fixtures only for isolated local demos.
  ///
  /// When [sharedLocalDemo] is true this is a no-op so private fixtures cannot
  /// masquerade as the shared authority.
  static Future<void> seedPastimeFixturesIfIsolated({
    required InMemoryPastimeRepository pastimes,
    required bool sharedLocalDemo,
  }) async {
    if (sharedLocalDemo) {
      return;
    }
    await pastimes.save(
      pastime: OfflineFixtures.radioPastime,
      idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
    );
    await pastimes.save(
      pastime: OfflineFixtures.draftPuzzlePastime,
      idempotencyKey: IdempotencyKey(
        'demo-pastime-save-01932f00-0008-7000-8000-000000000802',
      ),
    );
    await pastimes.save(
      pastime: OfflineFixtures.archivedPhotosPastime,
      idempotencyKey: IdempotencyKey(
        'demo-pastime-save-01932f00-0008-7000-8000-000000000803',
      ),
    );
  }

  /// Seeds the deterministic conversation-topic fixtures only for isolated demos.
  static Future<void> seedConversationTopicFixturesIfIsolated({
    required InMemoryConversationTopicRepository topics,
    required bool sharedLocalDemo,
  }) async {
    if (sharedLocalDemo) {
      return;
    }
    await topics.save(
      topic: OfflineFixtures.gardenTalkTopic,
      idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
    );
    await topics.save(
      topic: OfflineFixtures.draftKitchenTopic,
      idempotencyKey: IdempotencyKey(
        'demo-topic-save-01932f00-0010-7000-8000-000000001002',
      ),
    );
    await topics.save(
      topic: OfflineFixtures.archivedMusicTopic,
      idempotencyKey: IdempotencyKey(
        'demo-topic-save-01932f00-0010-7000-8000-000000001003',
      ),
    );
  }

  /// Asks the shared authority to ensure the fictional baseline once,
  /// then pulls all records for [familySpaceId] through [engine].
  ///
  /// Safe to call from multiple clients — the server initializer is idempotent.
  static Future<SyncPullSummary> reconcileFromAuthority({
    required SyncEngine engine,
    required LocalDemoSyncTransport transport,
    FamilySpaceId? familySpaceId,
  }) async {
    final space = familySpaceId ?? LocalDemoFictionalBaseline.familySpaceId;
    await transport.ensureRemoteBaseline();
    return engine.pull(familySpaceId: space);
  }
}
