import '../identity/identifiers.dart';
import '../memories/memory_entry.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first memory port. Writes must be immediately readable.
abstract interface class MemoryRepository {
  Future<MemoryEntry> save({
    required MemoryEntry memory,
    required IdempotencyKey idempotencyKey,
  });

  Future<MemoryEntry?> findById(MemoryId id);

  Future<List<MemoryEntry>> listForFamily(FamilySpaceId familySpaceId);

  Future<MemoryEntry> softDelete({
    required MemoryId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
