import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('LogRedactor', () {
    test('redacts tokens, media URLs/paths, health values and content', () {
      final raw = [
        'Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig',
        'api_key=super-secret-demo',
        'https://xyz.supabase.co/storage/v1/object/garden.jpg',
        '01932f00-0002-7000-8000-0000000000a1/garden-demo.jpg',
        'kilograms=62.5 kg=63',
        'systolic=120 diastolic=80 120/80',
        'caption=Jardin secreto Demo',
        'title=Rutina manana',
      ].join(' | ');

      final redacted = LogRedactor.redact(raw);
      expect(redacted, isNot(contains('eyJ')));
      expect(redacted, isNot(contains('super-secret-demo')));
      expect(redacted, isNot(contains('supabase.co')));
      expect(redacted, isNot(contains('garden-demo.jpg')));
      expect(redacted, isNot(contains('62.5')));
      expect(redacted, isNot(contains('120/80')));
      expect(redacted, isNot(contains('Jardin secreto')));
      expect(redacted, contains('[REDACTED'));
    });

    test('redactContext blanks sensitive keys', () {
      final out = LogRedactor.redactContext({
        'event': 'sync.push',
        'token': 'abc',
        'kilograms': 62.5,
        'caption': 'Privado Demo',
        'aggregateId': OfflineFixtures.morningRoutineId.value,
      });
      expect(out['event'], 'sync.push');
      expect(out['token'], '[REDACTED]');
      expect(out['kilograms'], '[REDACTED_HEALTH]');
      expect(out['caption'], '[REDACTED]');
      expect(out['aggregateId'], OfflineFixtures.morningRoutineId.value);
    });
  });

  group('SessionBoundary', () {
    test('demo mode needs no remote configuration', () {
      expect(SessionBoundary.demo.isDemoOffline, isTrue);
      expect(SessionBoundary.demo.requiresNetwork, isFalse);
      expect(
        RemoteCredentialNames.injectableNames,
        contains(RemoteCredentialNames.supabaseUrl),
      );
      expect(
        RemoteCredentialNames.forbiddenClientNames,
        contains(RemoteCredentialNames.serviceRoleKey),
      );
    });

    test('named credentials expose env names only', () {
      final boundary = SessionBoundary.namedCredentials();
      expect(boundary.urlEnvName, 'MEMORA_SUPABASE_URL');
      expect(boundary.anonKeyEnvName, 'MEMORA_SUPABASE_ANON_KEY');
      expect(boundary.requiresNetwork, isTrue);
    });
  });
}
