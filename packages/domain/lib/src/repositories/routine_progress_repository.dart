import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../routines/routine_day_progress.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first routine day-progress port. Writes must be immediately readable.
abstract interface class RoutineProgressRepository {
  Future<RoutineDayProgress> save({
    required RoutineDayProgress progress,
    required IdempotencyKey idempotencyKey,
  });

  Future<RoutineDayProgress?> findById(RoutineProgressId id);

  Future<RoutineDayProgress?> findByRoutineAndDate({
    required RoutineId routineId,
    required DateTime localDate,
  });

  Future<List<RoutineDayProgress>> listForFamily(FamilySpaceId familySpaceId);

  Future<RoutineDayProgress> softDelete({
    required RoutineProgressId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
