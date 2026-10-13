import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user/android_on_device_speech_recognizer.dart';
import 'package:user/demo_composition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ejemplo.memora.user/on_device_speech');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('non-Android test composition defaults to FakeSpeechRecognizer', () {
    final composition = UserDemoComposition();
    expect(composition.speechRecognizer, isA<FakeSpeechRecognizer>());
    expect(
      AndroidOnDeviceSpeechRecognizer.isSupportedPlatform,
      Platform.isAndroid,
    );
  });

  test('adapter refuses listen when platform reports non-on-device', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'checkAvailability':
              return 'languagePackMissing';
            case 'permissionStatus':
              return 'granted';
            case 'listen':
              fail('listen must not be invoked without on-device availability');
            default:
              return null;
          }
        });

    final adapter = AndroidOnDeviceSpeechRecognizer(
      channel: channel,
      isAndroidPlatform: true,
    );
    expect(
      await adapter.checkAvailability(),
      SpeechRecognizerAvailability.languagePackMissing,
    );
    final outcome = await adapter.listen();
    expect(outcome, isA<SpeechUnavailableOutcome>());
  });

  test(
    'adapter passes onDeviceOnly=true and never requests network fallback',
    () async {
      MethodCall? listenCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'checkAvailability':
                return 'availableOnDevice';
              case 'permissionStatus':
                return 'granted';
              case 'listen':
                listenCall = call;
                return <String, Object?>{
                  'kind': 'recognized',
                  'text': 'quiero una actividad',
                };
              case 'release':
              case 'cancel':
                return null;
              default:
                return null;
            }
          });

      final adapter = AndroidOnDeviceSpeechRecognizer(
        channel: channel,
        isAndroidPlatform: true,
      );
      final outcome = await adapter.listen();
      expect(outcome, isA<SpeechRecognized>());
      expect(listenCall, isNotNull);
      final args = listenCall!.arguments as Map;
      expect(args['onDeviceOnly'], isTrue);
    },
  );

  test('manifest authorizes RECORD_AUDIO only among sensitive permissions', () {
    final xml = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(xml, contains('android.permission.RECORD_AUDIO'));
    expect(xml, isNot(contains('READ_CONTACTS')));
    expect(xml, isNot(contains('CALL_PHONE')));
    expect(xml, isNot(contains('ACCESS_FINE_LOCATION')));
    expect(xml, isNot(contains('READ_EXTERNAL_STORAGE')));
    expect(xml, contains('android.speech.RecognitionService'));
  });

  test('Kotlin plugin refuses network recognizer creation path', () {
    final kotlin = File(
      'android/app/src/main/kotlin/com/ejemplo/memora/user/OnDeviceSpeechPlugin.kt',
    ).readAsStringSync();
    expect(kotlin, contains('createOnDeviceSpeechRecognizer'));
    expect(kotlin, contains('isOnDeviceRecognitionAvailable'));
    expect(kotlin, isNot(contains('SpeechRecognizer.createSpeechRecognizer')));
    expect(kotlin, contains('onDeviceOnly'));
  });
}
