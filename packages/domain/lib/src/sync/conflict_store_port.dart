import '../identity/identifiers.dart';
import 'sync_conflict.dart';

/// Local store for recoverable sync conflicts (keep-both until resolution).
abstract interface class ConflictStorePort {
  Future<void> save(SyncConflict conflict);

  Future<SyncConflict?> findById(String id);

  Future<List<SyncConflict>> listUnresolved(FamilySpaceId familySpaceId);
}
