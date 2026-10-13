import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FamilySpaceDto parity', () {
    test('round-trips domain Familia Ejemplo fixture', () {
      final original = IdentityFixtures.familiaEjemploSpace;
      final dto = FamilySpaceDto.fromDomain(original);
      final restored = dto.toDomain();
      final json = dto.toJson();

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.householdTimezone, original.householdTimezone);
      expect(json['id'], original.id.value);
      expect(json['household_timezone'], 'Europe/Madrid');
      expect(FamilySpaceDto.fromJson(json).toDomain().id, original.id);
    });
  });

  group('FamilyMembershipDto parity', () {
    final fixtures = <FamilyMembership>[
      IdentityFixtures.elenaPrimaryMembership,
      IdentityFixtures.carlosCaregiverMembership,
      IdentityFixtures.luciaContributorMembership,
      IdentityFixtures.amparoSupportedMembership,
      IdentityFixtures.invitedCaregiverMembership,
      IdentityFixtures.revokedContributorMembership,
    ];

    for (final membership in fixtures) {
      test(
        'round-trips ${membership.role.wireName}/${membership.status.wireName}',
        () {
          final dto = FamilyMembershipDto.fromDomain(membership);
          final restored = dto.toDomain();
          final json = dto.toJson();

          expect(restored.id, membership.id);
          expect(restored.familySpaceId, membership.familySpaceId);
          expect(restored.userId, membership.userId);
          expect(restored.role, membership.role);
          expect(restored.status, membership.status);
          expect(json['role'], membership.role.wireName);
          expect(json['status'], membership.status.wireName);
          expect(
            FamilyMembershipDto.fromJson(json).toDomain().role,
            membership.role,
          );
        },
      );
    }

    test('wire names match SQL capability matrix role literals', () {
      expect(FamilyRole.values.map((r) => r.wireName).toSet(), {
        'supportedPerson',
        'primaryCaregiver',
        'caregiver',
        'familyContributor',
      });
      expect(MembershipStatus.values.map((s) => s.wireName).toSet(), {
        'active',
        'invited',
        'revoked',
      });
      expect(FamilyCapability.values.map((c) => c.wireName).toSet(), {
        'viewFamilySpace',
        'updateFamilySpace',
        'viewMemberships',
        'manageMemberships',
        'viewRoutines',
        'editRoutines',
        'recordRoutineProgress',
        'viewReminders',
        'configureReminders',
        'viewApprovedMemories',
        'manageMemories',
        'contributeMemories',
        'manageMediaMetadata',
        'viewObservations',
        'recordObservations',
        'resolveSyncConflicts',
        'viewPastimes',
        'editPastimes',
      });
    });
  });
}
