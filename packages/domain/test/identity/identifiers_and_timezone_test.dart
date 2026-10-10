import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('identifiers', () {
    test('accepts stable reserved UUIDs', () {
      expect(
        FamilySpaceId('01932f00-0002-7000-8000-0000000000a1').value,
        '01932f00-0002-7000-8000-0000000000a1',
      );
      expect(
        UserId('01932F00-0002-7000-8000-000000000101').value,
        '01932f00-0002-7000-8000-000000000101',
      );
    });

    test('rejects malformed UUIDs', () {
      expect(() => FamilySpaceId('not-a-uuid'), throwsFormatException);
      expect(() => FamilyMembershipId('1234'), throwsFormatException);
      expect(() => UserId(''), throwsFormatException);
      expect(
        () => FamilySpaceId('01932f00-0002-7000-8000-0000000000a1-extra'),
        throwsFormatException,
      );
    });
  });

  group('HouseholdTimezone', () {
    test('accepts IANA-shaped values including UTC', () {
      expect(HouseholdTimezone('Europe/Madrid').value, 'Europe/Madrid');
      expect(HouseholdTimezone('America/New_York').value, 'America/New_York');
      expect(HouseholdTimezone('Atlantic/Canary').value, 'Atlantic/Canary');
      expect(HouseholdTimezone('UTC').value, 'UTC');
    });

    test('rejects empty and unstructured values', () {
      expect(() => HouseholdTimezone(''), throwsFormatException);
      expect(() => HouseholdTimezone('   '), throwsFormatException);
      expect(() => HouseholdTimezone('Madrid'), throwsFormatException);
      expect(() => HouseholdTimezone('Europe'), throwsFormatException);
      expect(() => HouseholdTimezone('Europe/'), throwsFormatException);
      expect(() => HouseholdTimezone('../etc/passwd'), throwsFormatException);
      expect(() => HouseholdTimezone('Europe/Madrid!'), throwsFormatException);
    });
  });

  group('FamilySpace', () {
    test('requires non-empty display name', () {
      expect(
        () => FamilySpace(
          id: IdentityFixtures.familiaEjemploSpaceId,
          displayName: '  ',
          householdTimezone: HouseholdTimezone('UTC'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('wire parsers', () {
    test('parse role status and capability wire names', () {
      expect(FamilyRole.parse('caregiver'), FamilyRole.caregiver);
      expect(MembershipStatus.parse('revoked'), MembershipStatus.revoked);
      expect(
        FamilyCapability.parse('manageMemberships'),
        FamilyCapability.manageMemberships,
      );
    });

    test('reject unknown wire names', () {
      expect(() => FamilyRole.parse('admin'), throwsFormatException);
      expect(() => MembershipStatus.parse('pending'), throwsFormatException);
      expect(
        () => FamilyCapability.parse('deleteEverything'),
        throwsFormatException,
      );
    });
  });
}
