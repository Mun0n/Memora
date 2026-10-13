import 'in_memory_sync_authority.dart';
import 'local_demo_sync_config.dart';

/// Web/non-IO stub — the local demo sync server requires `dart:io`.
final class LocalDemoSyncServer {
  LocalDemoSyncServer._();

  String get baseUrl => LocalDemoSyncConfig.defaultBaseUrl;

  InMemorySyncAuthority get authority =>
      throw UnsupportedError('LocalDemoSyncServer requires dart:io');

  String? get snapshotPath => null;

  bool get isDurable => false;

  static Future<LocalDemoSyncServer> bind({
    String host = LocalDemoSyncConfig.defaultHost,
    int port = LocalDemoSyncConfig.defaultPort,
    InMemorySyncAuthority? authority,
    String? snapshotPath,
    bool ensureFictionalBaselineWhenEmpty = false,
  }) async {
    throw UnsupportedError(
      'LocalDemoSyncServer.bind requires dart:io (run via '
      'tool/run_local_demo_sync.sh on a VM host)',
    );
  }

  Future<void> reset() async {
    throw UnsupportedError('LocalDemoSyncServer requires dart:io');
  }

  Future<void> close() async {}
}
