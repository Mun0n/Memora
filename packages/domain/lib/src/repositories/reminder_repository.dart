import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../reminders/reminder.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first reminder port. Writes must be immediately readable.
abstract interface class ReminderRepository {
  Future<Reminder> save({
    required Reminder reminder,
    required IdempotencyKey idempotencyKey,
  });

  Future<Reminder?> findById(ReminderId id);

  Future<List<Reminder>> listForFamily(FamilySpaceId familySpaceId);

  Future<Reminder> softDelete({
    required ReminderId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
