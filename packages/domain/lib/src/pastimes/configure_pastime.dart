import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/pastime_repository.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'pastime.dart';
import 'pastime_care_policy.dart';
import 'pastime_lifecycle_status.dart';

/// Caregiver configure use cases for pastimes (create/edit/order/lifecycle).
///
/// Invalid field values throw before save so UI-held draft fields are preserved.
final class ConfigurePastime {
  ConfigurePastime(this._pastimes);

  final PastimeRepository _pastimes;

  Future<Pastime> create({
    required FamilyMembership actor,
    required PastimeId id,
    required FamilySpaceId familySpaceId,
    required String title,
    required String instruction,
    required IdempotencyKey idempotencyKey,
    PastimeLifecycleStatus lifecycleStatus = PastimeLifecycleStatus.draft,
    int? displayOrder,
  }) async {
    _assertCanEdit(actor, familySpaceId);
    if (lifecycleStatus == PastimeLifecycleStatus.active) {
      await _assertActiveLimit(familySpaceId, excluding: null);
    }
    final order = displayOrder ?? await _nextDisplayOrder(familySpaceId);
    final pastime = Pastime(
      id: id,
      familySpaceId: familySpaceId,
      title: title,
      instruction: instruction,
      displayOrder: order,
      lifecycleStatus: lifecycleStatus,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _pastimes.save(pastime: pastime, idempotencyKey: idempotencyKey);
  }

  Future<Pastime> edit({
    required FamilyMembership actor,
    required PastimeId id,
    required IdempotencyKey idempotencyKey,
    String? title,
    String? instruction,
  }) async {
    final current = await _requirePastime(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot edit deleted pastime: ${id.value}');
    }
    final updated = current.copyWith(
      title: title,
      instruction: instruction,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _pastimes.save(pastime: updated, idempotencyKey: idempotencyKey);
  }

  /// Reassigns contiguous zero-based [Pastime.displayOrder] for [orderedIds].
  Future<List<Pastime>> reorder({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
    required List<PastimeId> orderedIds,
    required IdempotencyKey idempotencyKey,
  }) async {
    _assertCanEdit(actor, familySpaceId);
    if (orderedIds.isEmpty) {
      throw ArgumentError.value(orderedIds, 'orderedIds', 'must be non-empty');
    }
    final existing = await _pastimes.listForFamily(familySpaceId);
    final live = existing.where((p) => !p.isDeleted).toList();
    if (orderedIds.length != live.length) {
      throw ArgumentError.value(
        orderedIds.map((id) => id.value).toList(),
        'orderedIds',
        'must include every non-deleted pastime in the family exactly once',
      );
    }
    final byId = {for (final p in live) p.id.value: p};
    final result = <Pastime>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final current = byId[id.value];
      if (current == null) {
        throw StateError('pastime not in family: ${id.value}');
      }
      final updated = current.copyWith(
        displayOrder: i,
        version: current.version.next(),
        syncState: SyncState.pending,
      );
      // One shared key prefix + index keeps each outbox row unique.
      final key = IdempotencyKey('${idempotencyKey.value}#$i');
      result.add(await _pastimes.save(pastime: updated, idempotencyKey: key));
    }
    return result;
  }

  Future<Pastime> activate({
    required FamilyMembership actor,
    required PastimeId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requirePastime(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot activate deleted pastime: ${id.value}');
    }
    if (current.lifecycleStatus != PastimeLifecycleStatus.active) {
      await _assertActiveLimit(current.familySpaceId, excluding: current.id);
    }
    final updated = current.copyWith(
      lifecycleStatus: PastimeLifecycleStatus.active,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _pastimes.save(pastime: updated, idempotencyKey: idempotencyKey);
  }

  Future<Pastime> archive({
    required FamilyMembership actor,
    required PastimeId id,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _requirePastime(id);
    _assertCanEdit(actor, current.familySpaceId);
    if (current.isDeleted) {
      throw StateError('cannot archive deleted pastime: ${id.value}');
    }
    final updated = current.copyWith(
      lifecycleStatus: PastimeLifecycleStatus.archived,
      version: current.version.next(),
      syncState: SyncState.pending,
    );
    return _pastimes.save(pastime: updated, idempotencyKey: idempotencyKey);
  }

  /// Active cached items for supported-person presentation, caregiver order.
  Future<List<Pastime>> listActiveForViewing({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!PastimeCarePolicy.canViewPastimes(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot view pastimes',
      );
    }
    return _pastimes.listActiveForFamily(familySpaceId);
  }

  void _assertCanEdit(FamilyMembership actor, FamilySpaceId spaceId) {
    _assertSameSpace(actor, spaceId);
    if (!PastimeCarePolicy.canEditPastimes(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot edit pastimes',
      );
    }
  }

  void _assertSameSpace(FamilyMembership actor, FamilySpaceId spaceId) {
    if (actor.familySpaceId != spaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${spaceId.value}',
      );
    }
  }

  Future<void> _assertActiveLimit(
    FamilySpaceId familySpaceId, {
    required PastimeId? excluding,
  }) async {
    final active = await _pastimes.listActiveForFamily(familySpaceId);
    final count = active
        .where((p) => excluding == null || p.id != excluding)
        .length;
    if (count >= Pastime.maxActivePerFamily) {
      throw StateError(
        'family already has ${Pastime.maxActivePerFamily} active pastimes',
      );
    }
  }

  Future<int> _nextDisplayOrder(FamilySpaceId familySpaceId) async {
    final listed = await _pastimes.listForFamily(familySpaceId);
    final live = listed.where((p) => !p.isDeleted);
    var max = -1;
    for (final p in live) {
      if (p.displayOrder > max) {
        max = p.displayOrder;
      }
    }
    return max + 1;
  }

  Future<Pastime> _requirePastime(PastimeId id) async {
    final current = await _pastimes.findById(id);
    if (current == null) {
      throw StateError('pastime not found: ${id.value}');
    }
    return current;
  }
}
