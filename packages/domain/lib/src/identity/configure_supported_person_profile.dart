import '../offline/offline_identifiers.dart';
import '../repositories/supported_person_profile_repository.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'family_membership.dart';
import 'identifiers.dart';
import 'supported_person_profile.dart';
import 'supported_person_profile_care_policy.dart';

/// Primary-caregiver configure use cases for the preferred-name profile.
///
/// Invalid field values throw before save so UI-held draft fields are preserved.
final class ConfigureSupportedPersonProfile {
  ConfigureSupportedPersonProfile(this._profiles);

  final SupportedPersonProfileRepository _profiles;

  /// Creates or corrects the single preferred-name profile for [familySpaceId].
  ///
  /// When a live profile already exists, [id] must match it (or be omitted via
  /// the existing row). Invalid [preferredName] throws [ArgumentError] before
  /// any repository write.
  Future<SupportedPersonProfile> setPreferredName({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
    required String preferredName,
    required IdempotencyKey idempotencyKey,
    SupportedPersonProfileId? id,
  }) async {
    _assertCanEdit(actor, familySpaceId);
    // Validate before touching storage so invalid input preserves current value.
    final normalized = SupportedPersonProfile.normalizePreferredName(
      preferredName,
    );
    final existing = await _profiles.findForFamily(familySpaceId);
    if (existing != null && !existing.isDeleted) {
      if (id != null && id != existing.id) {
        throw StateError(
          'family already has a supported-person profile: ${existing.id.value}',
        );
      }
      final updated = existing.copyWith(
        preferredName: normalized,
        version: existing.version.next(),
        syncState: SyncState.pending,
      );
      return _profiles.save(profile: updated, idempotencyKey: idempotencyKey);
    }
    final profileId =
        id ??
        (throw ArgumentError.notNull(
          'id is required when creating a supported-person profile',
        ));
    final created = SupportedPersonProfile(
      id: profileId,
      familySpaceId: familySpaceId,
      preferredName: normalized,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _profiles.save(profile: created, idempotencyKey: idempotencyKey);
  }

  /// Cached profile for greeting / caregiver display (missing → null).
  Future<SupportedPersonProfile?> findForFamily({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertSameSpace(actor, familySpaceId);
    if (!SupportedPersonProfileCarePolicy.canViewSupportedPersonProfile(
      actor,
    )) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot view supported-person profile',
      );
    }
    final profile = await _profiles.findForFamily(familySpaceId);
    if (profile == null || profile.isDeleted) {
      return null;
    }
    return profile;
  }

  void _assertCanEdit(FamilyMembership actor, FamilySpaceId spaceId) {
    _assertSameSpace(actor, spaceId);
    if (!SupportedPersonProfileCarePolicy.canEditSupportedPersonProfile(
      actor,
    )) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot edit supported-person profile',
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
}
