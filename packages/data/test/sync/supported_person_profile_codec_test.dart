import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SupportedPersonProfileCodec', () {
    test('round-trips fictional Amparo Demo profile', () {
      final profile = OfflineFixtures.amparoPreferredNameProfile.copyWith(
        syncState: SyncState.synced,
      );
      final payload = SupportedPersonProfileCodec.encodePayload(profile);
      final decoded = SupportedPersonProfileCodec.decodeProfile(
        aggregateId: profile.id.value,
        familySpaceId: profile.familySpaceId.value,
        payload: payload,
        version: profile.version,
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(decoded.preferredName, 'Amparo Demo');
      expect(decoded.id, profile.id);
    });

    test('missing preferredName decodes as null (safe greeting fallback)', () {
      final decoded = SupportedPersonProfileCodec.tryDecodeProfile(
        aggregateId: OfflineFixtures.amparoPreferredNameProfileId.value,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId.value,
        payload: <String, Object?>{'version': 1},
        version: AggregateVersion(1),
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(decoded, isNull);
      expect(SupportedPersonProfile.homeGreeting(decoded), 'Hola');
    });

    test('invalid preferredName in payload decodes as null', () {
      final decoded = SupportedPersonProfileCodec.tryDecodeProfile(
        aggregateId: OfflineFixtures.amparoPreferredNameProfileId.value,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId.value,
        payload: <String, Object?>{'preferredName': '   '},
        version: AggregateVersion(1),
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(decoded, isNull);
    });
  });
}
