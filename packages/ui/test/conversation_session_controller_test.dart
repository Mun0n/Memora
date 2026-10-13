import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('UserConversationSessionController', () {
    late FakeSpeechRecognizer recognizer;
    late FakeSpeechOutput output;
    late UserConversationSessionController controller;

    setUp(() {
      recognizer = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      output = FakeSpeechOutput();
      controller = UserConversationSessionController(
        recognizer: recognizer,
        speechOutput: output,
        postSpeakPause: Duration.zero,
      );
    });

    tearDown(() async {
      output.autoComplete = true;
      output.completeCurrent();
      await controller.clear();
    });

    test(
      'start speaks introduction then first prompt before listening',
      () async {
        output.autoComplete = false;
        recognizer.enqueue(
          const SpeechRecognized('Me gustaba plantar tomates Demo'),
        );

        final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
        await _flush();
        expect(controller.phase, ConversationSessionPhase.topicIntroduction);
        expect(controller.memoraSpeaking, isTrue);
        expect(recognizer.listenCount, 0);

        output.completeCurrent();
        await _flush();
        expect(controller.phase, ConversationSessionPhase.promptReady);
        expect(controller.memoraSpeaking, isTrue);
        expect(recognizer.listenCount, 0);

        // Remaining ack / next-prompt speech may auto-complete after listen.
        output.autoComplete = true;
        output.completeCurrent();
        await startFuture;

        expect(output.speakCount, greaterThanOrEqualTo(2));
        expect(output.lastSpeechRate, SpeechOutputPort.defaultSpeechRate);
        expect(recognizer.listenCount, greaterThanOrEqualTo(1));
        expect(controller.microphoneOpen, isFalse);
        expect(controller.memoraSpeaking, isFalse);
      },
    );

    test('exact speak → completed → listen order for opening turn', () async {
      output.autoComplete = false;
      final events = <String>[];

      final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
      await _flush();
      expect(output.isSpeaking, isTrue);
      expect(controller.memoraSpeaking, isTrue);
      expect(controller.microphoneOpen, isFalse);
      expect(recognizer.listenCount, 0);
      events.add('speaking_intro');

      output.completeCurrent();
      await _flush();
      expect(controller.phase, ConversationSessionPhase.promptReady);
      expect(output.isSpeaking, isTrue);
      expect(recognizer.listenCount, 0);
      events.add('speaking_prompt');

      recognizer.enqueue(const SpeechRecognized('flores Demo'));
      output.autoComplete = true;
      output.completeCurrent();
      await startFuture;

      events.add('listened');
      expect(recognizer.listenCount, greaterThanOrEqualTo(1));
      expect(events, ['speaking_intro', 'speaking_prompt', 'listened']);
      expect(controller.microphoneOpen, isFalse);
    });

    test('no recognition while output is speaking', () async {
      output.autoComplete = false;
      final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
      await _flush();
      expect(controller.memoraSpeaking, isTrue);
      expect(recognizer.listenCount, 0);
      expect(recognizer.isListening, isFalse);

      output.completeCurrent();
      await _flush();
      expect(controller.memoraSpeaking, isTrue);
      expect(recognizer.listenCount, 0);

      recognizer.enqueue(const SpeechSilence());
      output.autoComplete = true;
      output.completeCurrent();
      await startFuture;
      expect(recognizer.listenCount, greaterThanOrEqualTo(1));
    });

    test(
      'acknowledgement and next prompt complete before next listen',
      () async {
        output.autoComplete = false;
        recognizer.enqueue(const SpeechRecognized('tomates Demo'));

        final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
        await _flush();
        output.completeCurrent(); // intro
        await _flush();
        output.completeCurrent(); // prompt 0 → listen
        await _flush();

        expect(controller.phase, ConversationSessionPhase.acknowledgement);
        expect(recognizer.listenCount, 1);
        final listensAfterFirst = recognizer.listenCount;

        expect(output.isSpeaking, isTrue); // ack
        expect(recognizer.listenCount, listensAfterFirst);
        output.completeCurrent(); // ack → advance to prompt 1
        await _flush();

        expect(controller.phase, ConversationSessionPhase.promptReady);
        expect(output.isSpeaking, isTrue);
        expect(recognizer.listenCount, listensAfterFirst);

        recognizer.enqueue(const SpeechSilence());
        output.autoComplete = true;
        output.completeCurrent(); // prompt 1 → listen
        await startFuture;
        expect(recognizer.listenCount, greaterThan(listensAfterFirst));
      },
    );

    test('closing never starts recognition', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      final listensBeforeFinish = recognizer.listenCount;
      await controller.finish();
      expect(controller.phase, ConversationSessionPhase.closing);
      expect(controller.displayedText, OfflineFixtures.gardenTalkTopic.closing);
      expect(controller.microphoneOpen, isFalse);
      expect(recognizer.listenCount, listensBeforeFinish);
    });

    test(
      'repeat re-speaks prompt then listens only after completion',
      () async {
        await controller.start(OfflineFixtures.gardenTalkTopic);
        final listensBefore = recognizer.listenCount;

        output.autoComplete = false;
        final repeatFuture = controller.repeat();
        await _flush();
        expect(controller.memoraSpeaking, isTrue);
        expect(recognizer.listenCount, listensBefore);
        recognizer.enqueue(const SpeechSilence());
        output.autoComplete = true;
        output.completeCurrent();
        await repeatFuture;
        expect(recognizer.listenCount, greaterThan(listensBefore));
      },
    );

    test(
      'stale speak completion after cancel never reopens microphone',
      () async {
        output.autoComplete = false;
        final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
        await _flush();
        expect(output.isSpeaking, isTrue);

        await controller.releaseForLifecycle();
        expect(controller.phase, ConversationSessionPhase.idle);

        output.completeCurrent();
        await startFuture;
        expect(recognizer.listenCount, 0);
        expect(controller.microphoneOpen, isFalse);
        expect(controller.phase, ConversationSessionPhase.idle);
      },
    );

    test('missing local voice keeps written flow and Hablar path', () async {
      output.availability = SpeechOutputAvailability.unavailable;
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.speechOutputUnavailable, isTrue);
      expect(controller.phase, ConversationSessionPhase.topicIntroduction);
      expect(recognizer.listenCount, 0);
      expect(output.speakCount, 0);

      await controller.confirmIntroduction();
      expect(controller.phase, ConversationSessionPhase.promptReady);
      expect(controller.needsManualListen, isTrue);
      expect(recognizer.listenCount, 0);

      recognizer.enqueue(const SpeechRecognized('jardín Demo'));
      await controller.beginManualListen();
      expect(recognizer.listenCount, 1);
      expect(controller.microphoneOpen, isFalse);
      expect(controller.phase, ConversationSessionPhase.acknowledgement);
    });

    test('network-only voices do not auto-listen', () async {
      output.availability = SpeechOutputAvailability.networkOnlyVoices;
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.speechOutputUnavailable, isTrue);
      expect(recognizer.listenCount, 0);
      expect(output.speakCount, 0);
    });

    test('output failure falls back to written Hablar path', () async {
      output.enqueue(const SpeechSpeakError('boom'));
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.speechOutputUnavailable, isTrue);
      expect(recognizer.listenCount, 0);
      expect(controller.phase, ConversationSessionPhase.topicIntroduction);
    });

    test('change topic stops output and clears for list return', () async {
      output.autoComplete = false;
      final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
      await _flush();
      await controller.changeTopic();
      expect(output.stopCount, greaterThan(0));
      expect(controller.phase, ConversationSessionPhase.cancelled);
      await controller.clear();
      expect(controller.phase, ConversationSessionPhase.idle);
      output.completeCurrent();
      await startFuture;
      expect(recognizer.listenCount, 0);
    });

    test('finish shows authored closing with mic released', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      await controller.finish();
      expect(controller.phase, ConversationSessionPhase.closing);
      expect(controller.displayedText, OfflineFixtures.gardenTalkTopic.closing);
      expect(controller.microphoneOpen, isFalse);
    });

    test('unavailable recognizer keeps written controls usable', () async {
      recognizer.availability = SpeechRecognizerAvailability.unavailable;
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(recognizer.listenCount, 0);
      expect(controller.phase, ConversationSessionPhase.unavailable);
      expect(controller.displayedText, MemoraCopy.quieroHablarUnavailable);
      expect(controller.microphoneOpen, isFalse);
    });

    test('permission denial keeps written controls without trapping', () async {
      recognizer.currentPermission = SpeechPermissionStatus.denied;
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(recognizer.listenCount, 0);
      expect(controller.phase, ConversationSessionPhase.unavailable);
      expect(controller.displayedText, MemoraCopy.quieroHablarUnavailable);
      expect(controller.microphoneOpen, isFalse);
    });

    test(
      'safety-sensitive speech stops listening and shows limitation',
      () async {
        recognizer.enqueue(const SpeechRecognized('Llama a emergencias'));
        await controller.start(OfflineFixtures.gardenTalkTopic);
        expect(controller.phase, ConversationSessionPhase.safetyStopped);
        expect(controller.displayedText, contains('no es un servicio médico'));
        expect(controller.microphoneOpen, isFalse);
      },
    );

    test(
      'lifecycle release clears session and releases mic and output',
      () async {
        await controller.start(OfflineFixtures.gardenTalkTopic);
        await controller.releaseForLifecycle();
        expect(controller.phase, ConversationSessionPhase.idle);
        expect(recognizer.releaseCount, greaterThan(0));
        expect(output.releaseCount, greaterThan(0));
      },
    );

    test('silence recovery after listen leaves mic closed', () async {
      recognizer.enqueue(const SpeechSilence());
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.microphoneOpen, isFalse);
      expect(
        controller.displayedText,
        anyOf(
          MemoraCopy.quieroHablarSilenceRecovery,
          OfflineFixtures.gardenTalkTopic.closing,
          OfflineFixtures.gardenTalkTopic.prompts[1].text,
          MemoraCopy.quieroHablarNeutralAck,
        ),
      );
    });
  });
}
