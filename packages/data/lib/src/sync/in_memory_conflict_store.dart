import 'package:domain/domain.dart';

/// Deterministic local conflict store for recoverable concurrent edits.
final class InMemoryConflictStore implements ConflictStorePort {
  final Map<String, SyncConflict> _byId = <String, SyncConflict>{};

  @override
  Future<void> save(SyncConflict conflict) async {
    _byId[conflict.id] = conflict;
  }

  @override
  Future<SyncConflict?> findById(String id) async => _byId[id];

  @override
  Future<List<SyncConflict>> listUnresolved(FamilySpaceId familySpaceId) async {
    return _byId.values
        .where((c) => c.familySpaceId == familySpaceId && c.isUnresolved)
        .toList(growable: false);
  }
}
