import 'dart:io';

import 'package:data/data.dart';

/// Loopback fictional-only demo sync authority for Slice 8 cross-client demos.
///
/// Usage:
/// ```bash
/// cd packages/data && dart run bin/local_demo_sync_server.dart
/// # or: ./tool/run_local_demo_sync.sh
/// ```
///
/// Durable snapshot (default): `packages/data/.local_demo_sync/authority_snapshot.json`
/// Override: `MEMORA_LOCAL_DEMO_SYNC_SNAPSHOT=/abs/path.json`
/// Reset (restores fictional pastime baseline):
///   `curl -X POST http://127.0.0.1:17808/v1/reset`
/// Stop: Ctrl+C. No credentials. Payload bodies are never printed.
Future<void> main(List<String> args) async {
  final host =
      Platform.environment['MEMORA_LOCAL_DEMO_SYNC_HOST'] ??
      LocalDemoSyncConfig.defaultHost;
  final portRaw = Platform.environment['MEMORA_LOCAL_DEMO_SYNC_PORT'];
  final port = portRaw == null
      ? LocalDemoSyncConfig.defaultPort
      : int.parse(portRaw);
  final snapshotPath =
      Platform.environment[LocalDemoSyncConfig.snapshotEnvironmentKey] ??
      [
        Directory.current.path,
        LocalDemoSyncConfig.defaultSnapshotDirectoryName,
        LocalDemoSyncConfig.defaultSnapshotFileName,
      ].join(Platform.pathSeparator);

  late final LocalDemoSyncServer server;
  try {
    server = await LocalDemoSyncServer.bind(
      host: host,
      port: port,
      snapshotPath: snapshotPath,
      ensureFictionalBaselineWhenEmpty: true,
    );
  } on LocalDemoSyncSnapshotException catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }

  stdout.writeln(
    'Memora local demo sync listening on ${server.baseUrl} '
    '(fictional data only; loopback; durable)',
  );
  stdout.writeln('Snapshot: ${server.snapshotPath}');
  stdout.writeln('Health: GET  ${server.baseUrl}/v1/health');
  stdout.writeln(
    'Bootstrap: POST ${server.baseUrl}/v1/bootstrap '
    '(idempotent pastime baseline)',
  );
  stdout.writeln(
    'Reset:  POST ${server.baseUrl}/v1/reset '
    '(clears snapshot rows and restores fictional baseline)',
  );
  stdout.writeln(
    'Clients: --dart-define=${LocalDemoSyncConfig.urlEnvironmentKey}='
    '${server.baseUrl}',
  );

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
