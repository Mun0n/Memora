import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/routine_repository.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'routine.dart';
import 'routine_care_policy.dart';
import 'routine_lifecycle_status.dart';
import 'routine_step.dart';
import 'unauthorized_care_action_exception.dart';

/// Caregiver/family configure use cases for routines (create/edit/order/lifecycle).
final class ConfigureRoutine {
  ConfigureRoutine(this._routines);

  final RoutineRepository _routines;

  Future<Routine> create({
    required FamilyMembership actor,
    required RoutineId id,
    required FamilySpaceId familySpaceId,
    required String title,
    required List<RoutineStep> steps,
    required IdempotencyKey idempotencyKey,
    RoutineLifecycleStatus lifecycleStatus = RoutineLifecycleStatus.active,
  }) async {
    _assertCanConfigure(actor, familySpaceId);
    final routine = Routine(
      id: id,
      familySpaceId: familySpaceId,
      title: title,
      steps: steps,
      lifecycleStatus: lifecycleStatus,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _routines.save(routine: routine, idempotencyKey: idempotencyKey);
  }

  Future<Routine> edit({
    required FamilyMembership actor,
    required RoutineId id,
    required IdempotencyKey idempotencyKey,
    String? title,
    List<RoutineStep>? steps,
  }) async {
    final current = await _requireRoutine(id);
    _assertCanConfigure(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot edit deleted routine: ${id.value}');
    }
    final updated = current.copyWith(
      title: title,
      steps: steps,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _routines.save(routine: updated, idempotencyKey: idempotencyKey);
  }

  Future<Routine> reorderSteps({
    required FamilyMembership actor,
    required RoutineId id,
    required List<RoutineStep> steps,
    required IdempotencyKey idempotencyKey,
  }) {
    return edit(
      actor: actor,
      id: id,
      steps: steps,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Routine> activate({
    required FamilyMembership actor,
    required RoutineId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireRoutine(id);
    _assertCanConfigure(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot activate deleted routine: ${id.value}');
    }
    final updated = current.copyWith(
      lifecycleStatus: RoutineLifecycleStatus.active,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _routines.save(routine: updated, idempotencyKey: idempotencyKey);
  }

  Future<Routine> archive({
    required FamilyMembership actor,
    required RoutineId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requireRoutine(id);
    _assertCanConfigure(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot archive deleted routine: ${id.value}');
    }
    final updated = current.copyWith(
      lifecycleStatus: RoutineLifecycleStatus.archived,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _routines.save(routine: updated, idempotencyKey: idempotencyKey);
  }

  void _assertCanConfigure(FamilyMembership actor, FamilySpaceId spaceId) {
    if (actor.familySpaceId != spaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${spaceId.value}',
      );
    }
    if (!RoutineCarePolicy.canConfigureCareContent(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot configure routines',
      );
    }
  }

  Future<Routine> _requireRoutine(RoutineId id) async {
    final current = await _routines.findById(id);
    if (current == null) {
      throw StateError('routine not found: ${id.value}');
    }
    return current;
  }
}
