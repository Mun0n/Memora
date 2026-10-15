import 'package:domain/domain.dart';

/// Device-local in-memory recovery store (not part of sync/outbox snapshots).
final class InMemoryPastimeSessionRecoveryStore
    implements PastimeSessionRecoveryPort {
  PastimeSessionRecoverySnapshot? _current;

  /// Optional clock for expiry tests.
  DateTime Function() now = () => DateTime.now().toUtc();

  @override
  Future<PastimeSessionRecoverySnapshot?> loadCurrent() async {
    final current = _current;
    if (current == null) {
      return null;
    }
    if (current.isExpiredAt(now())) {
      _current = null;
      return null;
    }
    return current;
  }

  @override
  Future<void> save(PastimeSessionRecoverySnapshot snapshot) async {
    if (snapshot.isExpiredAt(now())) {
      _current = null;
      return;
    }
    _current = snapshot;
  }

  @override
  Future<void> clear() async {
    _current = null;
  }

  @override
  Future<void> clearIfMatches({
    required PastimeId pastimeId,
    String? experienceType,
    int? experienceSchemaVersion,
  }) async {
    final current = _current;
    if (current == null || current.pastimeId != pastimeId) {
      return;
    }
    // Delete-by-id (Terminar / pastime deleted): no type/version filter.
    if (experienceType == null && experienceSchemaVersion == null) {
      _current = null;
      return;
    }
    // Definition changed → discard incompatible recovery.
    final typeChanged =
        experienceType != null && current.experienceType != experienceType;
    final versionChanged =
        experienceSchemaVersion != null &&
        current.experienceSchemaVersion != experienceSchemaVersion;
    if (typeChanged || versionChanged) {
      _current = null;
    }
  }
}
