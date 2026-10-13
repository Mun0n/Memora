import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeSpeechOutput', () {
    test(
      'default speak completes without estimating from text length',
      () async {
        final fake = FakeSpeechOutput();
        final outcome = await fake.speak(
          'Tu familia me ha contado que te gustaba cuidar el jardín',
        );
        expect(outcome, isA<SpeechSpeakCompleted>());
        expect(fake.speakCount, 1);
        expect(fake.isSpeaking, isFalse);
        expect(fake.retainedUtteranceForTest, isNull);
        expect(fake.lastSpeechRate, SpeechOutputPort.defaultSpeechRate);
        expect(SpeechOutputPort.defaultSpeechRate, 0.90);
      },
    );

    test('availability gate rejects speak without local voice', () async {
      final unavailable = FakeSpeechOutput(
        availability: SpeechOutputAvailability.unavailable,
      );
      expect(
        await unavailable.checkAvailability(),
        SpeechOutputAvailability.unavailable,
      );
      expect(
        await unavailable.speak('Introducción Demo'),
        isA<SpeechSpeakUnavailable>(),
      );
      expect(unavailable.isSpeaking, isFalse);

      final networkOnly = FakeSpeechOutput(
        availability: SpeechOutputAvailability.networkOnlyVoices,
      );
      final outcome = await networkOnly.speak('Introducción Demo');
      expect(outcome, isA<SpeechSpeakUnavailable>());
      expect(
        (outcome as SpeechSpeakUnavailable).availability,
        SpeechOutputAvailability.networkOnlyVoices,
      );
    });

    test('manual completion models real utterance callbacks', () async {
      final fake = FakeSpeechOutput(autoComplete: false);
      final future = fake.speak('Invitación Demo');
      expect(fake.isSpeaking, isTrue);
      expect(fake.retainedUtteranceForTest, 'Invitación Demo');
      fake.completeCurrent();
      expect(await future, isA<SpeechSpeakCompleted>());
      expect(fake.isSpeaking, isFalse);
      expect(fake.retainedUtteranceForTest, isNull);
    });

    test('stop cancels in-flight speak and clears utterance text', () async {
      final fake = FakeSpeechOutput(autoComplete: false);
      final future = fake.speak('Cierre Demo');
      expect(fake.isSpeaking, isTrue);
      await fake.stop();
      expect(await future, isA<SpeechSpeakCancelled>());
      expect(fake.isSpeaking, isFalse);
      expect(fake.retainedUtteranceForTest, isNull);
      expect(fake.stopCount, 1);
    });

    test('release clears queue and retains no utterance history', () async {
      final fake = FakeSpeechOutput(autoComplete: false);
      fake.enqueue(const SpeechSpeakError('should_not_leak'));
      final future = fake.speak('Texto Demo efímero');
      await fake.release();
      expect(await future, isA<SpeechSpeakCancelled>());
      expect(fake.retainedUtteranceForTest, isNull);
      expect(fake.releaseCount, 1);

      // After release, autoComplete speak has an empty queue → completed.
      fake.autoComplete = true;
      fake.availability = SpeechOutputAvailability.availableOnDevice;
      expect(await fake.speak('Otro'), isA<SpeechSpeakCompleted>());
    });

    test('queued error outcomes surface without inventing speech', () async {
      final fake = FakeSpeechOutput();
      fake.enqueue(const SpeechSpeakError('engine_busy'));
      final outcome = await fake.speak('Prompt Demo');
      expect(outcome, isA<SpeechSpeakError>());
      expect((outcome as SpeechSpeakError).code, 'engine_busy');
    });

    test('custom speech rate is observed', () async {
      final fake = FakeSpeechOutput();
      await fake.speak('Hola Demo', speechRate: 0.85);
      expect(fake.lastSpeechRate, 0.85);
    });
  });
}
