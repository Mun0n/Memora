import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../routines/routine.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first routine port. Writes must be immediately readable.
abstract interface class RoutineRepository {
  Future<Routine> save({
    required Routine routine,
    required IdempotencyKey idempotencyKey,
  });

  Future<Routine?> findById(RoutineId id);

  Future<List<Routine>> listForFamily(FamilySpaceId familySpaceId);

  Future<Routine> softDelete({
    required RoutineId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
