import 'package:domain/domain.dart';

import 'fake_supabase_remote.dart';
import 'local_demo_sync_config.dart';
import 'local_demo_sync_transport.dart';

/// Selects the demo [SyncTransportPort] for composition roots.
///
/// When a non-empty shared URL is configured, returns
/// [LocalDemoSyncTransport]. Otherwise returns a private in-process
/// [FakeSupabaseRemote] (isolated local demonstration — changes do not reach
/// other processes).
SyncTransportPort createDemoSyncTransport({String? baseUrl}) {
  final resolved = LocalDemoSyncConfig.resolveConfiguredUrl(explicit: baseUrl);
  if (resolved != null) {
    return LocalDemoSyncTransport(baseUrl: resolved);
  }
  return FakeSupabaseRemote();
}

/// Whether the composition is using the shared local demo transport.
bool isSharedLocalDemoTransportConfigured({String? baseUrl}) {
  return LocalDemoSyncConfig.resolveConfiguredUrl(explicit: baseUrl) != null;
}
