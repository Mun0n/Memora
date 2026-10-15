import 'dart:convert';
import 'dart:io';

import 'package:domain/domain.dart';

/// Durable device-local recovery store (VM/IO). Not synced or audited.
///
/// Atomic write (temp + rename). Corrupt or incompatible files are discarded
/// safely — never crash or fabricate a session. Web-safe barrel uses a stub.
final class FilePastimeSessionRecoveryStore
    implements PastimeSessionRecoveryPort {
  FilePastimeSessionRecoveryStore(this.path);

  final String path;

  /// Optional clock for expiry tests.
  DateTime Function() now = () => DateTime.now().toUtc();

  File get _file => File(path);

  @override
  Future<PastimeSessionRecoverySnapshot?> loadCurrent() async {
    if (!_file.existsSync()) {
      return null;
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(await _file.readAsString());
    } on Object {
      await _deleteQuietly();
      return null;
    }
    final snapshot = PastimeSessionRecoverySnapshot.tryParse(decoded);
    if (snapshot == null) {
      await _deleteQuietly();
      return null;
    }
    if (snapshot.isExpiredAt(now())) {
      await _deleteQuietly();
      return null;
    }
    return snapshot;
  }

  @override
  Future<void> save(PastimeSessionRecoverySnapshot snapshot) async {
    if (snapshot.isExpiredAt(now())) {
      await clear();
      return;
    }
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(snapshot.toMap()));
    if (_file.existsSync()) {
      await _file.delete();
    }
    await tmp.rename(_file.path);
  }

  @override
  Future<void> clear() async {
    await _deleteQuietly();
  }

  @override
  Future<void> clearIfMatches({
    required PastimeId pastimeId,
    String? experienceType,
    int? experienceSchemaVersion,
  }) async {
    final current = await loadCurrent();
    if (current == null || current.pastimeId != pastimeId) {
      return;
    }
    if (experienceType == null && experienceSchemaVersion == null) {
      await clear();
      return;
    }
    final typeChanged =
        experienceType != null && current.experienceType != experienceType;
    final versionChanged =
        experienceSchemaVersion != null &&
        current.experienceSchemaVersion != experienceSchemaVersion;
    if (typeChanged || versionChanged) {
      await clear();
    }
  }

  Future<void> _deleteQuietly() async {
    if (_file.existsSync()) {
      await _file.delete();
    }
    final tmp = File('${_file.path}.tmp');
    if (tmp.existsSync()) {
      await tmp.delete();
    }
  }
}
