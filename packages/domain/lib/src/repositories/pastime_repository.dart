import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../pastimes/pastime.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first pastime port. Writes must be immediately readable.
abstract interface class PastimeRepository {
  Future<Pastime> save({
    required Pastime pastime,
    required IdempotencyKey idempotencyKey,
  });

  Future<Pastime?> findById(PastimeId id);

  Future<List<Pastime>> listForFamily(FamilySpaceId familySpaceId);

  /// Active, non-tombstoned pastimes ordered by [Pastime.displayOrder].
  Future<List<Pastime>> listActiveForFamily(FamilySpaceId familySpaceId);

  Future<Pastime> softDelete({
    required PastimeId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
