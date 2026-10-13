import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeSpeechRecognizer', () {
    test('default composition never invents speech', () async {
      final fake = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      expect(fake.isListening, isFalse);
      final outcome = await fake.listen();
      expect(outcome, isA<SpeechTimeout>());
      expect(fake.isListening, isFalse);
      expect(fake.listenCount, 1);
    });

    test('availability gate before listen', () async {
      final fake = FakeSpeechRecognizer(
        availability: SpeechRecognizerAvailability.unavailable,
        currentPermission: SpeechPermissionStatus.granted,
      );
      final outcome = await fake.listen();
      expect(outcome, isA<SpeechUnavailableOutcome>());
      expect(
        (outcome as SpeechUnavailableOutcome).availability,
        SpeechRecognizerAvailability.unavailable,
      );
    });

    test('language pack missing is distinct', () async {
      final fake = FakeSpeechRecognizer(
        availability: SpeechRecognizerAvailability.languagePackMissing,
        currentPermission: SpeechPermissionStatus.granted,
      );
      expect(
        await fake.checkAvailability(),
        SpeechRecognizerAvailability.languagePackMissing,
      );
      final outcome = await fake.listen();
      expect(
        (outcome as SpeechUnavailableOutcome).availability,
        SpeechRecognizerAvailability.languagePackMissing,
      );
    });

    test('permission denial outcomes are distinct', () async {
      final denied = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.denied,
      );
      expect(await denied.listen(), isA<SpeechPermissionDeniedOutcome>());
      expect(
        (await denied.listen() as SpeechPermissionDeniedOutcome).permanent,
        isFalse,
      );

      final permanent = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.permanentlyDenied,
      );
      final outcome = await permanent.listen();
      expect(outcome, isA<SpeechPermissionDeniedOutcome>());
      expect((outcome as SpeechPermissionDeniedOutcome).permanent, isTrue);

      // Permanent denial must not flip on request.
      expect(
        await permanent.requestPermission(),
        SpeechPermissionStatus.permanentlyDenied,
      );
    });

    test('in-context requestPermission can grant or deny', () async {
      final grant = FakeSpeechRecognizer(grantOnRequest: true);
      expect(
        await grant.permissionStatus(),
        SpeechPermissionStatus.notDetermined,
      );
      expect(await grant.requestPermission(), SpeechPermissionStatus.granted);

      final deny = FakeSpeechRecognizer(grantOnRequest: false);
      expect(await deny.requestPermission(), SpeechPermissionStatus.denied);
    });

    test('queued outcomes cover silence, cancel, error, recognized', () async {
      final fake = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
        nextOutcomes: const <SpeechListenOutcome>[
          SpeechSilence(),
          SpeechCancelled(),
          SpeechListenError('demo_error'),
          SpeechRecognized('Quiero ver mi día'),
        ],
      );

      expect(await fake.listen(), isA<SpeechSilence>());
      expect(await fake.listen(), isA<SpeechCancelled>());
      final err = await fake.listen();
      expect(err, isA<SpeechListenError>());
      expect((err as SpeechListenError).code, 'demo_error');
      final ok = await fake.listen();
      expect(ok, isA<SpeechRecognized>());
      expect((ok as SpeechRecognized).textInMemory, 'Quiero ver mi día');
    });

    test('cancel and release clear listening and are countable', () async {
      final fake = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      fake.forceNextOutcome = const SpeechRecognized('Demo');
      // listen clears listening in finally; cancel/release still track.
      await fake.listen();
      await fake.cancel();
      await fake.release();
      await fake.release();
      expect(fake.cancelCount, 1);
      expect(fake.releaseCount, 2);
      expect(fake.isListening, isFalse);
    });

    test('nothing listens until listen is called', () {
      final fake = FakeSpeechRecognizer();
      expect(fake.listenCount, 0);
      expect(fake.isListening, isFalse);
      expect(fake.checkAvailabilityCount, 0);
    });
  });
}
