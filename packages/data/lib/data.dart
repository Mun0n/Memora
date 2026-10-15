/// Memora data layer: transport-neutral DTOs and deterministic local adapters.
///
/// Dependency rule: may depend on `domain` only among project packages.
/// No Flutter, Supabase client or credentials.
/// Sync uses an in-process [FakeSupabaseRemote] by default; separately running
/// demo clients may share [LocalDemoSyncTransport] against a loopback
/// [LocalDemoSyncServer]. Android Drift wiring remains deferred.
library;

export 'src/identity/family_membership_dto.dart';
export 'src/identity/family_space_dto.dart';
export 'src/offline/in_memory_conversation_topic_repository.dart';
export 'src/offline/in_memory_memory_repository.dart';
export 'src/offline/in_memory_observation_repositories.dart';
export 'src/offline/in_memory_offline_store.dart';
export 'src/offline/in_memory_outbox.dart';
export 'src/offline/in_memory_pastime_repository.dart';
export 'src/offline/in_memory_pastime_session_recovery_store.dart';
export 'src/offline/file_pastime_session_recovery_store_export.dart';

export 'src/offline/in_memory_reminder_repository.dart';
export 'src/offline/in_memory_routine_progress_repository.dart';
export 'src/offline/in_memory_routine_repository.dart';
export 'src/offline/in_memory_supported_person_profile_repository.dart';
export 'src/offline/offline_store_snapshot.dart';
export 'src/sync/conversation_topic_codec.dart';
export 'src/sync/pastime_codec.dart';
export 'src/sync/supported_person_profile_codec.dart';
export 'src/sync/demo_sync_transport_factory.dart';
export 'src/sync/fake_supabase_remote.dart';
export 'src/sync/in_memory_audit_store.dart';
export 'src/sync/in_memory_conflict_store.dart';
export 'src/sync/in_memory_privacy_store.dart';
export 'src/sync/in_memory_sync_authority.dart';
export 'src/sync/local_demo_fictional_baseline.dart';
export 'src/sync/local_demo_shared_bootstrap.dart';
export 'src/sync/local_demo_sync_config.dart';
export 'src/sync/local_demo_sync_server.dart';
export 'src/sync/local_demo_sync_transport.dart';
export 'src/sync/offline_sync_bridge.dart';
export 'src/synthetic_persona_catalog.dart';
