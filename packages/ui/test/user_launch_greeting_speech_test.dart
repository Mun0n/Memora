import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('UserLaunchGreetingSpeech', () {
    late FakeSpeechOutput output;
    late FakeSpeechRecognizer recognizer;
    late UserLaunchGreetingSpeech speech;

    setUp(() {
      output = FakeSpeechOutput();
      recognizer = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      speech = UserLaunchGreetingSpeech(speechOutput: output);
    });

    tearDown(() async {
      output.autoComplete = true;
      output.completeCurrent();
      await speech.cancel();
    });

    test('speaks greeting then invitation exactly once', () async {
      output.autoComplete = false;
      final future = speech.speakOnceIfNeeded(
        greeting: 'Hola, Amparo',
        isOnHome: true,
      );
      await _flush();
      expect(speech.attempted, isTrue);
      expect(speech.inFlight, isTrue);
      expect(output.retainedUtteranceForTest, 'Hola, Amparo');
      expect(recognizer.listenCount, 0);

      output.completeCurrent();
      await _flush();
      expect(output.retainedUtteranceForTest, MemoraCopy.userHomeInvitation);
      expect(recognizer.listenCount, 0);

      output.completeCurrent();
      await future;
      expect(speech.inFlight, isFalse);
      expect(output.speakCount, 2);
      expect(recognizer.listenCount, 0);
      expect(recognizer.requestPermissionCount, 0);
    });

    test('second call after attempt is a no-op', () async {
      await speech.speakOnceIfNeeded(greeting: 'Hola, Amparo', isOnHome: true);
      final speaks = output.speakCount;
      await speech.speakOnceIfNeeded(greeting: 'Hola, Amparo', isOnHome: true);
      expect(output.speakCount, speaks);
    });

    test('off-home does not speak or mark attempted', () async {
      await speech.speakOnceIfNeeded(greeting: 'Hola', isOnHome: false);
      expect(speech.attempted, isFalse);
      expect(output.speakCount, 0);
    });

    test('unavailable TTS marks attempted and leaves home usable', () async {
      output.availability = SpeechOutputAvailability.unavailable;
      await speech.speakOnceIfNeeded(greeting: 'Hola', isOnHome: true);
      expect(speech.attempted, isTrue);
      expect(output.speakCount, 0);
      expect(recognizer.listenCount, 0);
    });

    test('safe fallback greeting when empty string', () async {
      output.autoComplete = false;
      final future = speech.speakOnceIfNeeded(greeting: '  ', isOnHome: true);
      await _flush();
      expect(output.retainedUtteranceForTest, MemoraCopy.userHomeGreeting);
      output.completeCurrent();
      await _flush();
      output.completeCurrent();
      await future;
      expect(output.speakCount, 2);
    });

    test('cancel stops in-flight greeting without opening mic', () async {
      output.autoComplete = false;
      final future = speech.speakOnceIfNeeded(
        greeting: 'Hola, Amparo',
        isOnHome: true,
      );
      await _flush();
      await speech.cancel();
      await future;
      expect(speech.inFlight, isFalse);
      expect(output.stopCount, greaterThan(0));
      expect(recognizer.listenCount, 0);

      // Already attempted — resume must not re-speak.
      output.autoComplete = true;
      await speech.speakOnceIfNeeded(greeting: 'Hola, Amparo', isOnHome: true);
      expect(output.speakCount, 1);
    });

    test('speak failure still marks attempted and does not trap', () async {
      output.enqueue(const SpeechSpeakError('tts'));
      await speech.speakOnceIfNeeded(greeting: 'Hola', isOnHome: true);
      expect(speech.attempted, isTrue);
      expect(speech.inFlight, isFalse);
      expect(output.speakCount, 1);
      expect(recognizer.listenCount, 0);
    });
  });
}
