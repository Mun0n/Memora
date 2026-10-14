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
      expect(controller.phase, ConversationSessionPhase.idle);
      expect(controller.hasActiveSession, isFalse);
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

    test('finish speaks closing once then clears session to idle', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.hasActiveSession, isTrue);

      output.autoComplete = false;
      final finishFuture = controller.finish();
      await _flush();
      expect(controller.isFinishing, isTrue);
      expect(controller.phase, ConversationSessionPhase.closing);
      expect(controller.displayedText, OfflineFixtures.gardenTalkTopic.closing);
      expect(controller.microphoneOpen, isFalse);
      expect(
        output.retainedUtteranceForTest,
        OfflineFixtures.gardenTalkTopic.closing,
      );

      output.completeCurrent();
      await finishFuture;
      expect(controller.phase, ConversationSessionPhase.idle);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.isFinishing, isFalse);
      expect(controller.microphoneOpen, isFalse);
      expect(output.releaseCount, greaterThan(0));
    });

    test('finish with unavailable TTS still clears to idle', () async {
      output.availability = SpeechOutputAvailability.unavailable;
      await controller.start(OfflineFixtures.gardenTalkTopic);
      await controller.finish();
      expect(controller.phase, ConversationSessionPhase.idle);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.microphoneOpen, isFalse);
    });

    test('finish cancelled TTS still clears to idle', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      output.autoComplete = false;
      final finishFuture = controller.finish();
      await _flush();
      expect(controller.phase, ConversationSessionPhase.closing);
      output.completeCurrent(const SpeechSpeakCancelled());
      await finishFuture;
      expect(controller.phase, ConversationSessionPhase.idle);
      expect(controller.hasActiveSession, isFalse);
    });

    test('finish error TTS still clears to idle', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      output.autoComplete = false;
      final finishFuture = controller.finish();
      await _flush();
      output.failCurrent('tts');
      await finishFuture;
      expect(controller.phase, ConversationSessionPhase.idle);
      expect(controller.hasActiveSession, isFalse);
    });

    test('duplicate finish while in flight is ignored', () async {
      await controller.start(OfflineFixtures.gardenTalkTopic);
      output.autoComplete = false;
      final first = controller.finish();
      await _flush();
      final speaksBeforeDuplicate = output.speakCount;
      await controller.finish();
      expect(output.speakCount, speaksBeforeDuplicate);
      output.completeCurrent();
      await first;
      expect(controller.phase, ConversationSessionPhase.idle);
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

    test(
      'Dame una idea speaks help then returns to same prompt before listen',
      () async {
        output.availability = SpeechOutputAvailability.unavailable;
        await controller.start(OfflineFixtures.gardenTalkTopic);
        await controller.confirmIntroduction();
        expect(controller.phase, ConversationSessionPhase.promptReady);
        expect(controller.canRequestHelp, isTrue);
        expect(controller.snapshot.promptIndex, 0);

        // Written path: reveal help without TTS, stay on same prompt.
        await controller.requestHelp();
        expect(controller.helpRevealed, isTrue);
        expect(
          controller.revealedHelpCue,
          OfflineFixtures.gardenTalkTopic.prompts[0].help!.cue,
        );
        expect(controller.snapshot.promptIndex, 0);
        expect(controller.phase, ConversationSessionPhase.promptReady);
        expect(controller.microphoneOpen, isFalse);
        expect(controller.canRequestHelp, isTrue);
      },
    );

    test(
      'help speak → complete → listen serialization keeps same prompt',
      () async {
        output.autoComplete = false;
        final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
        await _flush();
        output.completeCurrent(); // intro
        await _flush();
        output.completeCurrent(); // prompt 0 → listen → timeout → ack speech
        await _flush();
        expect(controller.snapshot.promptIndex, 0);
        final listensBefore = recognizer.listenCount;

        // Stops any in-flight ack speech, then presents authored help.
        final helpFuture = controller.requestHelp();
        await _flush();
        expect(controller.phase, ConversationSessionPhase.presentingHelp);
        expect(controller.memoraSpeaking, isTrue);
        expect(controller.microphoneOpen, isFalse);
        expect(controller.snapshot.promptIndex, 0);

        // Help speak must finish before any further recognition.
        expect(recognizer.listenCount, listensBefore);
        output.completeCurrent(); // help utterance completes
        await _flush();
        expect(controller.helpRevealed, isTrue);
        expect(controller.snapshot.promptIndex, 0);
        expect(controller.microphoneOpen, isFalse);
        // Listen may already have opened (and timed out) after help speech.
        expect(recognizer.listenCount, greaterThan(listensBefore));

        output.autoComplete = true;
        output.completeCurrent();
        await helpFuture;
        await startFuture;
      },
    );

    test('exact spoken help command reveals cue without advancing', () async {
      output.autoComplete = false;
      recognizer.enqueue(const SpeechRecognized('Dame una idea'));
      final startFuture = controller.start(OfflineFixtures.gardenTalkTopic);
      await _flush();
      output.completeCurrent(); // intro
      await _flush();
      output.completeCurrent(); // prompt → listen → Dame una idea → help speak
      await _flush();
      expect(controller.phase, ConversationSessionPhase.presentingHelp);
      expect(controller.helpRevealed, isTrue);
      expect(controller.snapshot.promptIndex, 0);
      expect(controller.microphoneOpen, isFalse);
      expect(
        controller.revealedHelpCue,
        OfflineFixtures.gardenTalkTopic.prompts[0].help!.cue,
      );
      output.autoComplete = true;
      output.completeCurrent();
      await startFuture;
    });

    test('ordinary answer with idea words does not reveal help', () async {
      recognizer.enqueue(
        const SpeechRecognized('Me gusta la idea de plantar tomates Demo'),
      );
      await controller.start(OfflineFixtures.gardenTalkTopic);
      expect(controller.helpRevealed, isFalse);
      expect(controller.snapshot.lastCommand, isNot(ConversationCommand.help));
    });

    test('prompt without help hides Dame una idea affordance', () async {
      final topic = ConversationTopic(
        id: OfflineFixtures.gardenTalkTopicId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Sin ayuda Demo',
        introduction: 'Introducción Demo para conversar con calma.',
        prompts: <ConversationPrompt>[
          ConversationPrompt(
            order: 0,
            text: 'Cuéntame algo del jardín Ejemplo cuando quieras.',
          ),
        ],
        closing: 'Gracias por compartir un rato.',
        displayOrder: 0,
        lifecycleStatus: ConversationTopicLifecycleStatus.active,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
      output.availability = SpeechOutputAvailability.unavailable;
      await controller.start(topic);
      await controller.confirmIntroduction();
      expect(controller.canRequestHelp, isFalse);
      await controller.requestHelp();
      expect(controller.helpRevealed, isFalse);
      expect(controller.displayedText, ConversationCopy.helpUnavailable);
    });
  });
}
