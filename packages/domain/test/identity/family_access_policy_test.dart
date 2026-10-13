import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FamilyAccessPolicy capability matrix', () {
    final cases = <(FamilyRole, FamilyCapability, bool)>[
      // Identity wires
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
      // Product wires (Slice 6)
      (FamilyRole.supportedPerson, FamilyCapability.viewRoutines, true),
      (FamilyRole.supportedPerson, FamilyCapability.editRoutines, false),
      (
        FamilyRole.supportedPerson,
        FamilyCapability.recordRoutineProgress,
        true,
      ),
      (FamilyRole.supportedPerson, FamilyCapability.viewReminders, true),
      (FamilyRole.supportedPerson, FamilyCapability.configureReminders, false),
      (FamilyRole.supportedPerson, FamilyCapability.viewApprovedMemories, true),
      (FamilyRole.supportedPerson, FamilyCapability.manageMemories, false),
      (FamilyRole.supportedPerson, FamilyCapability.contributeMemories, false),
      (FamilyRole.supportedPerson, FamilyCapability.manageMediaMetadata, false),
      (FamilyRole.supportedPerson, FamilyCapability.viewObservations, false),
      (FamilyRole.supportedPerson, FamilyCapability.recordObservations, false),
      (
        FamilyRole.supportedPerson,
        FamilyCapability.resolveSyncConflicts,
        false,
      ),
      (FamilyRole.supportedPerson, FamilyCapability.viewPastimes, true),
      (FamilyRole.supportedPerson, FamilyCapability.editPastimes, false),
      (
        FamilyRole.supportedPerson,
        FamilyCapability.viewConversationTopics,
        true,
      ),
      (
        FamilyRole.supportedPerson,
        FamilyCapability.editConversationTopics,
        false,
      ),
      (FamilyRole.primaryCaregiver, FamilyCapability.editRoutines, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.configureReminders, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.manageMemories, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.manageMediaMetadata, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.recordObservations, true),
      (
        FamilyRole.primaryCaregiver,
        FamilyCapability.resolveSyncConflicts,
        true,
      ),
      (
        FamilyRole.primaryCaregiver,
        FamilyCapability.recordRoutineProgress,
        false,
      ),
      (FamilyRole.primaryCaregiver, FamilyCapability.contributeMemories, false),
      (FamilyRole.primaryCaregiver, FamilyCapability.viewPastimes, true),
      (FamilyRole.primaryCaregiver, FamilyCapability.editPastimes, true),
      (
        FamilyRole.primaryCaregiver,
        FamilyCapability.viewConversationTopics,
        true,
      ),
      (
        FamilyRole.primaryCaregiver,
        FamilyCapability.editConversationTopics,
        true,
      ),
      (FamilyRole.caregiver, FamilyCapability.editRoutines, true),
      (FamilyRole.caregiver, FamilyCapability.manageMemories, true),
      (FamilyRole.caregiver, FamilyCapability.recordObservations, true),
      (FamilyRole.caregiver, FamilyCapability.resolveSyncConflicts, true),
      (FamilyRole.caregiver, FamilyCapability.contributeMemories, false),
      (FamilyRole.caregiver, FamilyCapability.viewPastimes, true),
      (FamilyRole.caregiver, FamilyCapability.editPastimes, true),
      (FamilyRole.caregiver, FamilyCapability.viewConversationTopics, true),
      (FamilyRole.caregiver, FamilyCapability.editConversationTopics, true),
      (FamilyRole.familyContributor, FamilyCapability.viewRoutines, true),
      (FamilyRole.familyContributor, FamilyCapability.contributeMemories, true),
      (
        FamilyRole.familyContributor,
        FamilyCapability.viewApprovedMemories,
        true,
      ),
      (FamilyRole.familyContributor, FamilyCapability.editRoutines, false),
      (
        FamilyRole.familyContributor,
        FamilyCapability.recordObservations,
        false,
      ),
      (
        FamilyRole.familyContributor,
        FamilyCapability.configureReminders,
        false,
      ),
      (
        FamilyRole.familyContributor,
        FamilyCapability.resolveSyncConflicts,
        false,
      ),
      (FamilyRole.familyContributor, FamilyCapability.viewPastimes, false),
      (FamilyRole.familyContributor, FamilyCapability.editPastimes, false),
      (
        FamilyRole.familyContributor,
        FamilyCapability.viewConversationTopics,
        false,
      ),
      (
        FamilyRole.familyContributor,
        FamilyCapability.editConversationTopics,
        false,
      ),
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

  group('care policies use capability wires', () {
    test('RoutineCarePolicy mirrors editRoutines / progress / resolve', () {
      expect(
        RoutineCarePolicy.canConfigureCareContent(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        RoutineCarePolicy.canRecordStepProgress(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        RoutineCarePolicy.canResolveSyncConflicts(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isTrue,
      );
      expect(
        RoutineCarePolicy.canConfigureCareContent(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
    });

    test('MemoryCarePolicy mirrors manage / contribute / viewApproved', () {
      expect(
        MemoryCarePolicy.canManageMemories(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canContributeMemories(
          IdentityFixtures.luciaContributorMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canViewApprovedMemories(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
    });

    test('ObservationCarePolicy caregiver-only', () {
      expect(
        ObservationCarePolicy.canRecordObservations(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isTrue,
      );
      expect(
        ObservationCarePolicy.canRecordObservations(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isFalse,
      );
    });

    test('PastimeCarePolicy mirrors viewPastimes / editPastimes', () {
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        PastimeCarePolicy.canViewPastimes(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
      expect(
        PastimeCarePolicy.canViewPastimes(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
    });
  });
}
