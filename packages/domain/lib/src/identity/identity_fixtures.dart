import 'family_membership.dart';
import 'family_role.dart';
import 'family_space.dart';
import 'household_timezone.dart';
import 'identifiers.dart';
import 'membership_status.dart';

/// Stable reserved fictional identity fixtures for Slice 2 contracts.
///
/// Labels use Demo/Ejemplo only. UUIDs are reserved for tests and SQL proofs;
/// they are not production identifiers.
abstract final class IdentityFixtures {
  // --- Family spaces -------------------------------------------------------

  static final FamilySpaceId familiaEjemploSpaceId = FamilySpaceId(
    '01932f00-0002-7000-8000-0000000000a1',
  );

  static final FamilySpaceId casaDemoBSpaceId = FamilySpaceId(
    '01932f00-0002-7000-8000-0000000000b2',
  );

  static final FamilySpace familiaEjemploSpace = FamilySpace(
    id: familiaEjemploSpaceId,
    displayName: 'Familia Ejemplo',
    householdTimezone: HouseholdTimezone('Europe/Madrid'),
  );

  static final FamilySpace casaDemoBSpace = FamilySpace(
    id: casaDemoBSpaceId,
    displayName: 'Casa Demo B',
    householdTimezone: HouseholdTimezone('Atlantic/Canary'),
  );

  // --- Authenticated identities --------------------------------------------

  static final UserId elenaPrimaryUserId = UserId(
    '01932f00-0002-7000-8000-000000000101',
  );

  static final UserId carlosCaregiverUserId = UserId(
    '01932f00-0002-7000-8000-000000000102',
  );

  static final UserId luciaContributorUserId = UserId(
    '01932f00-0002-7000-8000-000000000103',
  );

  static final UserId amparoSupportedUserId = UserId(
    '01932f00-0002-7000-8000-000000000104',
  );

  static final UserId outsiderDemoUserId = UserId(
    '01932f00-0002-7000-8000-000000000199',
  );

  // --- Memberships in Familia Ejemplo --------------------------------------

  static final FamilyMembership elenaPrimaryMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000201'),
    familySpaceId: familiaEjemploSpaceId,
    userId: elenaPrimaryUserId,
    role: FamilyRole.primaryCaregiver,
    status: MembershipStatus.active,
  );

  static final FamilyMembership carlosCaregiverMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000202'),
    familySpaceId: familiaEjemploSpaceId,
    userId: carlosCaregiverUserId,
    role: FamilyRole.caregiver,
    status: MembershipStatus.active,
  );

  static final FamilyMembership luciaContributorMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000203'),
    familySpaceId: familiaEjemploSpaceId,
    userId: luciaContributorUserId,
    role: FamilyRole.familyContributor,
    status: MembershipStatus.active,
  );

  static final FamilyMembership amparoSupportedMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000204'),
    familySpaceId: familiaEjemploSpaceId,
    userId: amparoSupportedUserId,
    role: FamilyRole.supportedPerson,
    status: MembershipStatus.active,
  );

  /// Invited caregiver in Familia Ejemplo — grants no capabilities.
  static final FamilyMembership invitedCaregiverMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000205'),
    familySpaceId: familiaEjemploSpaceId,
    userId: UserId('01932f00-0002-7000-8000-000000000105'),
    role: FamilyRole.caregiver,
    status: MembershipStatus.invited,
  );

  /// Revoked contributor in Familia Ejemplo — grants no capabilities.
  static final FamilyMembership revokedContributorMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000206'),
    familySpaceId: familiaEjemploSpaceId,
    userId: UserId('01932f00-0002-7000-8000-000000000106'),
    role: FamilyRole.familyContributor,
    status: MembershipStatus.revoked,
  );

  /// Active primary in Casa Demo B for cross-family isolation proofs.
  static final FamilyMembership casaDemoBPrimaryMembership = FamilyMembership(
    id: FamilyMembershipId('01932f00-0002-7000-8000-000000000211'),
    familySpaceId: casaDemoBSpaceId,
    userId: UserId('01932f00-0002-7000-8000-000000000111'),
    role: FamilyRole.primaryCaregiver,
    status: MembershipStatus.active,
  );

  static const String elenaPrimaryDisplayName = 'Elena Demo';
  static const String amparoSupportedDisplayName = 'Amparo Demo';
  static const String carlosCaregiverDisplayName = 'Carlos Demo';
  static const String luciaContributorDisplayName = 'Lucia Demo';
  static const String outsiderDisplayName = 'Outsider Demo';
}
