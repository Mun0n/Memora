import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/reminder_repository.dart';
import '../routines/routine_care_policy.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'quiet_hours.dart';
import 'reminder.dart';

/// Caregiver-configured convenience reminder create/edit (no delivery transport).
final class ConfigureReminder {
  ConfigureReminder(this._reminders);

  final ReminderRepository _reminders;

  Future<Reminder> create({
    required FamilyMembership actor,
    required ReminderId id,
    required FamilySpaceId familySpaceId,
    required String title,
    required DateTime scheduledAt,
    required IdempotencyKey idempotencyKey,
    QuietHours? quietHours,
  }) async {
    _assertCanConfigure(actor, familySpaceId);
    final reminder = Reminder(
      id: id,
      familySpaceId: familySpaceId,
      title: title,
      scheduledAt: scheduledAt,
      quietHours: quietHours,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _reminders.save(reminder: reminder, idempotencyKey: idempotencyKey);
  }

  Future<Reminder> edit({
    required FamilyMembership actor,
    required ReminderId id,
    required IdempotencyKey idempotencyKey,
    String? title,
    DateTime? scheduledAt,
    QuietHours? quietHours,
    bool clearQuietHours = false,
  }) async {
    final current = await _reminders.findById(id);
    if (current == null) {
      throw StateError('reminder not found: ${id.value}');
    }
    _assertCanConfigure(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot edit deleted reminder: ${id.value}');
    }
    final updated = current.copyWith(
      title: title,
      scheduledAt: scheduledAt,
      quietHours: quietHours,
      clearQuietHours: clearQuietHours,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _reminders.save(reminder: updated, idempotencyKey: idempotencyKey);
  }

  void _assertCanConfigure(FamilyMembership actor, FamilySpaceId spaceId) {
    if (actor.familySpaceId != spaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${spaceId.value}',
      );
    }
    if (!RoutineCarePolicy.canConfigureCareContent(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot configure reminders',
      );
    }
  }
}
