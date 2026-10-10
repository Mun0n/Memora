import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FamilyAccessPolicy capability matrix', () {
    final cases = <(FamilyRole, FamilyCapability, bool)>[
      (FamilyRole.supportedPerson, FamilyCapability.viewFamilySpace, true),
      (FamilyRole.supportedPerson, FamilyCapability.updateFamilySpace, false),
      (FamilyRole.supportedPerson, FamilyCapability.viewMemberships, false),
      (FamilyRole.supportedPerson, FamilyCapability.manageMemberships, false),
      (FamilyRole.primaryCaregiver, FamilyCapability.viewFamilySpace, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.updateFamilySpace, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.viewMemberships, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.manageMemberships, true),
      (FamilyRole.caregiver, FamilyCapability.viewFamilySpace, true),
      (FamilyRole.caregiver, FamilyCapability.updateFamilySpace, false),
      (FamilyRole.caregiver, FamilyCapability.viewMemberships, true),
      (FamilyRole.caregiver, FamilyCapability.manageMemberships, false),
      (FamilyRole.familyContributor, FamilyCapability.viewFamilySpace, true),
      (FamilyRole.familyContributor, FamilyCapability.updateFamilySpace, false),
      (FamilyRole.familyContributor, FamilyCapability.viewMemberships, false),
      (FamilyRole.familyContributor, FamilyCapability.manageMemberships, false),
    ];

    for (final (role, capability, expected) in cases) {
      test('$role + $capability => $expected when active', () {
        final membership = FamilyMembership(
          id: FamilyMembershipId('01932f00-0002-7000-8000-000000000301'),
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          userId: IdentityFixtures.elenaPrimaryUserId,
          role: role,
          status: MembershipStatus.active,
        );
        expect(FamilyAccessPolicy.allows(membership, capability), expected);
        expect(
          FamilyAccessPolicy.capabilitiesFor(role).contains(capability),
          expected,
        );
      });
    }

    for (final status in [MembershipStatus.invited, MembershipStatus.revoked]) {
      for (final role in FamilyRole.values) {
        for (final capability in FamilyCapability.values) {
          test('$role/$status grants no $capability', () {
            final membership = FamilyMembership(
              id: FamilyMembershipId('01932f00-0002-7000-8000-000000000302'),
              familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
              userId: IdentityFixtures.elenaPrimaryUserId,
              role: role,
              status: status,
            );
            expect(FamilyAccessPolicy.allows(membership, capability), isFalse);
          });
        }
      }
    }
  });

  group('canViewMembershipRow', () {
    test(
      'active contributor can read own membership without viewMemberships',
      () {
        final own = IdentityFixtures.luciaContributorMembership;
        expect(
          FamilyAccessPolicy.canViewMembershipRow(actor: own, target: own),
          isTrue,
        );
        expect(
          FamilyAccessPolicy.allows(own, FamilyCapability.viewMemberships),
          isFalse,
        );
      },
    );

    test('active contributor cannot read another membership', () {
      expect(
        FamilyAccessPolicy.canViewMembershipRow(
          actor: IdentityFixtures.luciaContributorMembership,
          target: IdentityFixtures.amparoSupportedMembership,
        ),
        isFalse,
      );
    });

    test('caregiver with viewMemberships can read another membership', () {
      expect(
        FamilyAccessPolicy.canViewMembershipRow(
          actor: IdentityFixtures.carlosCaregiverMembership,
          target: IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
    });

    test('invited membership cannot read own row', () {
      final invited = IdentityFixtures.invitedCaregiverMembership;
      expect(
        FamilyAccessPolicy.canViewMembershipRow(
          actor: invited,
          target: invited,
        ),
        isFalse,
      );
    });

    test('cross-family membership rows are denied', () {
      expect(
        FamilyAccessPolicy.canViewMembershipRow(
          actor: IdentityFixtures.elenaPrimaryMembership,
          target: IdentityFixtures.casaDemoBPrimaryMembership,
        ),
        isFalse,
      );
    });
  });
}
