import 'dart:convert';
import 'dart:io';

import 'in_memory_sync_authority.dart';
import 'local_demo_fictional_baseline.dart';

/// Atomic file persistence for the loopback fictional demo authority.
///
/// Stores no credentials or personal data. Corrupt or incompatible snapshots
/// fail loudly — they never silently fall back to unrelated fixtures.
/// VM/IO only; not exported from the web-safe `package:data` barrel.
final class LocalDemoSyncSnapshotStore {
  LocalDemoSyncSnapshotStore(this.path);

  final String path;

  File get _file => File(path);

  bool get exists => _file.existsSync();

  /// Loads an authority from disk. Missing file → empty authority.
  InMemorySyncAuthority load() {
    if (!exists) {
      return InMemorySyncAuthority();
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(_file.readAsStringSync());
    } on FormatException catch (error) {
      throw LocalDemoSyncSnapshotException(
        'corrupt local demo snapshot at $path (${error.message}). '
        'Delete the file or POST /v1/reset, then restart '
        './tool/run_local_demo_sync.sh',
      );
    }
    if (decoded is! Map) {
      throw LocalDemoSyncSnapshotException(
        'incompatible local demo snapshot at $path '
        '(expected a JSON object). Delete the file or POST /v1/reset, then '
        'restart ./tool/run_local_demo_sync.sh',
      );
    }
    final map = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
    final schema = map['schemaVersion'];
    if (schema != LocalDemoFictionalBaseline.schemaVersion) {
      throw LocalDemoSyncSnapshotException(
        'incompatible local demo snapshot schema at $path '
        '(found $schema, expected ${LocalDemoFictionalBaseline.schemaVersion}). '
        'Delete the file or POST /v1/reset, then restart '
        './tool/run_local_demo_sync.sh',
      );
    }
    final mode = map['mode'];
    if (mode != 'local_fictional_demo') {
      throw LocalDemoSyncSnapshotException(
        'incompatible local demo snapshot mode at $path '
        '(found $mode). Delete the file or POST /v1/reset, then restart '
        './tool/run_local_demo_sync.sh',
      );
    }
    try {
      return InMemorySyncAuthority.fromSnapshot(map);
    } on FormatException catch (error) {
      throw LocalDemoSyncSnapshotException(
        'corrupt local demo snapshot at $path (${error.message}). '
        'Delete the file or POST /v1/reset, then restart '
        './tool/run_local_demo_sync.sh',
      );
    }
  }

  /// Atomically writes [authority] (temp file + rename).
  Future<void> save(InMemorySyncAuthority authority) async {
    final file = _file;
    await file.parent.create(recursive: true);
    final payload = <String, Object?>{
      'schemaVersion': LocalDemoFictionalBaseline.schemaVersion,
      'mode': 'local_fictional_demo',
      ...authority.exportSnapshot(),
    };
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    if (file.existsSync()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  /// Removes the snapshot file when present.
  Future<void> delete() async {
    if (exists) {
      await _file.delete();
    }
    final tmp = File('${_file.path}.tmp');
    if (tmp.existsSync()) {
      await tmp.delete();
    }
  }
}
