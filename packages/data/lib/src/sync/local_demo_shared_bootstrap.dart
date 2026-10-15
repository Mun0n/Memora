import 'package:domain/domain.dart';

import '../offline/in_memory_conversation_topic_repository.dart';
import '../offline/in_memory_pastime_repository.dart';
import '../offline/in_memory_supported_person_profile_repository.dart';
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
      pastime: OfflineFixtures.sudokuDemoPastime,
      idempotencyKey: OfflineFixtures.sudokuDemoPastimeSaveKey,
    );
    await pastimes.save(
      pastime: OfflineFixtures.wordSearchDemoPastime,
      idempotencyKey: OfflineFixtures.wordSearchDemoPastimeSaveKey,
    );
    await pastimes.save(
      pastime: OfflineFixtures.spiderSolitaireDemoPastime,
      idempotencyKey: OfflineFixtures.spiderSolitaireDemoPastimeSaveKey,
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

  /// Seeds the fictional preferred-name profile only for isolated local demos.
  static Future<void> seedSupportedPersonProfileFixturesIfIsolated({
    required InMemorySupportedPersonProfileRepository profiles,
    required bool sharedLocalDemo,
  }) async {
    if (sharedLocalDemo) {
      return;
    }
    await profiles.save(
      profile: OfflineFixtures.amparoPreferredNameProfile,
      idempotencyKey: OfflineFixtures.amparoPreferredNameSaveKey,
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
