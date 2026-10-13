import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user/android_local_speech_output.dart';
import 'package:user/demo_composition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ejemplo.memora.user/local_speech_output');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('non-Android test composition defaults to FakeSpeechOutput', () {
    final composition = UserDemoComposition();
    expect(composition.speechOutput, isA<FakeSpeechOutput>());
    expect(AndroidLocalSpeechOutput.isSupportedPlatform, Platform.isAndroid);
  });

  test('adapter reports networkOnlyVoices without speaking', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'checkAvailability':
              return 'networkOnlyVoices';
            case 'speak':
              fail('speak must not run without a local Spanish voice');
            default:
              return null;
          }
        });

    final adapter = AndroidLocalSpeechOutput(
      channel: channel,
      isAndroidPlatform: true,
    );
    expect(
      await adapter.checkAvailability(),
      SpeechOutputAvailability.networkOnlyVoices,
    );
    final outcome = await adapter.speak('Texto Demo');
    expect(outcome, isA<SpeechSpeakUnavailable>());
    expect(
      (outcome as SpeechSpeakUnavailable).availability,
      SpeechOutputAvailability.networkOnlyVoices,
    );
  });

  test('adapter passes localOnly and default speech rate 0.90', () async {
    MethodCall? speakCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'checkAvailability':
              return 'availableOnDevice';
            case 'speak':
              speakCall = call;
              return <String, Object?>{'kind': 'completed'};
            case 'stop':
            case 'release':
              return null;
            default:
              return null;
          }
        });

    final adapter = AndroidLocalSpeechOutput(
      channel: channel,
      isAndroidPlatform: true,
    );
    final outcome = await adapter.speak('Invitación Demo');
    expect(outcome, isA<SpeechSpeakCompleted>());
    expect(speakCall, isNotNull);
    final args = speakCall!.arguments as Map;
    expect(args['localOnly'], isTrue);
    expect(args['speechRate'], SpeechOutputPort.defaultSpeechRate);
    expect(args['text'], 'Invitación Demo');
  });

  test(
    'Kotlin plugin rejects network-required voices and uses utterance callbacks',
    () {
      final kotlin = File(
        'android/app/src/main/kotlin/com/ejemplo/memora/user/LocalSpeechOutputPlugin.kt',
      ).readAsStringSync();
      expect(kotlin, contains('isNetworkConnectionRequired'));
      expect(kotlin, contains('UtteranceProgressListener'));
      expect(kotlin, contains('onDone'));
      expect(kotlin, contains('localOnly'));
      expect(kotlin, isNot(contains('CountDownTimer')));
      expect(kotlin, isNot(contains('text.length')));
      expect(kotlin, contains('UtteranceProgressListener'));
    },
  );

  test('MainActivity registers LocalSpeechOutputPlugin', () {
    final main = File(
      'android/app/src/main/kotlin/com/ejemplo/memora/user/MainActivity.kt',
    ).readAsStringSync();
    expect(main, contains('LocalSpeechOutputPlugin()'));
  });
}
