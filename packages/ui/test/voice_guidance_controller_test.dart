import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  group('UserVoiceGuidanceController', () {
    late FakeSpeechRecognizer fake;
    late UserVoiceGuidanceController controller;

    setUp(() {
      fake = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      controller = UserVoiceGuidanceController(
        recognizer: fake,
        contentSnapshot: () => VoiceContentSnapshot.allAvailable,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('does not listen before explicit tap', () async {
      expect(fake.listenCount, 0);
      expect(controller.phase, VoiceGuidancePhase.idle);
      expect(fake.isListening, isFalse);
    });

    test('unavailable recognizer never listens', () async {
      fake.availability = SpeechRecognizerAvailability.unavailable;
      await controller.startFromExplicitTap();
      expect(fake.listenCount, 0);
      expect(controller.phase, VoiceGuidancePhase.unavailable);
      expect(controller.message, MemoraCopy.voiceRecognizerUnavailable);
      expect(fake.releaseCount, greaterThan(0));
    });

    test('permission explain before first request', () async {
      fake.currentPermission = SpeechPermissionStatus.notDetermined;
      await controller.startFromExplicitTap();
      expect(fake.listenCount, 0);
      expect(fake.requestPermissionCount, 0);
      expect(controller.phase, VoiceGuidancePhase.permissionExplain);
      expect(controller.message, MemoraCopy.voicePermissionExplain);

      fake.enqueue(const SpeechRecognized('quiero una actividad'));
      await controller.confirmPermissionAndListen();
      expect(fake.requestPermissionCount, 1);
      expect(fake.listenCount, 1);
      expect(controller.phase, VoiceGuidancePhase.suggestion);
      expect(
        controller.suggestedDestination,
        HomeGuidanceDestination.pasatiempos,
      );
    });

    test('permission denial recovers without trapping', () async {
      fake.currentPermission = SpeechPermissionStatus.notDetermined;
      fake.grantOnRequest = false;
      await controller.startFromExplicitTap();
      await controller.confirmPermissionAndListen();
      expect(fake.listenCount, 0);
      expect(controller.phase, VoiceGuidancePhase.permissionDenied);
      await controller.dismissToHome();
      expect(controller.phase, VoiceGuidancePhase.idle);
    });

    test('recognized pastime suggests and navigates only on confirm', () async {
      fake.enqueue(const SpeechRecognized('quiero una actividad'));
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.suggestion);
      expect(controller.message, MemoraCopy.voiceSuggestPasatiempos);
      expect(controller.recognizedText, 'quiero una actividad');
      expect(controller.navigationTarget, UserHomeDestination.pasatiempos);

      final target = await controller.confirmNavigate();
      expect(target, UserHomeDestination.pasatiempos);
      expect(controller.phase, VoiceGuidancePhase.idle);
      expect(fake.releaseCount, greaterThan(0));
    });

    test('cancel restores idle and releases mic', () async {
      fake.enqueue(const SpeechTimeout());
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.timeout);
      await controller.cancel();
      expect(controller.phase, VoiceGuidancePhase.idle);
      expect(fake.cancelCount + fake.releaseCount, greaterThan(0));
    });

    test('silence / timeout / error are distinct recovery phases', () async {
      fake.enqueue(const SpeechSilence());
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.silence);

      fake.enqueue(const SpeechTimeout());
      await controller.retry();
      expect(controller.phase, VoiceGuidancePhase.timeout);

      fake.enqueue(const SpeechListenError('boom'));
      await controller.retry();
      expect(controller.phase, VoiceGuidancePhase.error);
    });

    test('unclear and safety never suggest a destination', () async {
      fake.enqueue(const SpeechRecognized('asdf qwerty'));
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.unclear);
      expect(controller.suggestedDestination, isNull);

      await controller.cancel();
      fake.enqueue(const SpeechRecognized('Llama a emergencias'));
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.safetyLimitation);
      expect(controller.suggestedDestination, isNull);
      expect(controller.message, contains('no es un servicio médico'));
    });

    test('Quiero hablar suggestion stays honest placeholder', () async {
      fake.enqueue(const SpeechRecognized('quiero hablar con alguien'));
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.suggestion);
      expect(
        controller.suggestedDestination,
        HomeGuidanceDestination.quieroHablar,
      );
      expect(controller.message, contains('no se hace ninguna llamada'));
    });

    test('lifecycle release cancels listening session', () async {
      // Hang listen by using a custom fake that stays listening — force cancel path.
      fake.forceNextOutcome = const SpeechCancelled();
      await controller.startFromExplicitTap();
      expect(controller.phase, VoiceGuidancePhase.idle);
      await controller.releaseForLifecycle();
      expect(fake.releaseCount, greaterThan(0));
    });

    test(
      'controller exposes transcript only until the flow is dismissed',
      () async {
        const secret = 'quiero una actividad secreta de prueba';
        fake.enqueue(const SpeechRecognized(secret));
        await controller.startFromExplicitTap();
        expect(controller.phase, VoiceGuidancePhase.suggestion);
        expect(controller.recognizedText, secret);
        expect(controller.message, isNot(contains('secreta')));
        expect(controller.message, isNot(contains('prueba')));
        expect(controller.message, MemoraCopy.voiceSuggestPasatiempos);
        await controller.dismissToHome();
        expect(controller.recognizedText, isNull);
      },
    );
  });
}
