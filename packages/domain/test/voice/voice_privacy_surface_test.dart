import 'dart:io';

import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Proves the voice recommendation path has no persistence / sync / audit /
/// transport surface for audio, transcript, intent or suggestion history.
void main() {
  group('voice privacy surface', () {
    test('recommendation path is pure and holds no transcript on decision', () {
      final decision = VoiceRecommendationPolicy.recommend(
        textInMemory: 'Quiero ver fotos de la familia Ejemplo',
        content: VoiceContentSnapshot.allAvailable,
      );

      expect(decision.destination, HomeGuidanceDestination.recuerdos);
      // Decision must not echo the transcript.
      expect(decision.message.toLowerCase(), isNot(contains('ejemplo')));
      expect(decision.message.toLowerCase(), isNot(contains('fotos de')));
    });

    test('fake recognizer does not retain transcripts after listen', () async {
      final fake = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      fake.enqueue(const SpeechRecognized('Texto Demo efímero'));
      final outcome = await fake.listen();
      expect(outcome, isA<SpeechRecognized>());
      // Queue drained — no second copy retained for later listen.
      expect(await fake.listen(), isA<SpeechTimeout>());
    });

    test(
      'voice lib sources do not reference sync/audit/outbox persistence',
      () {
        final voiceDir = Directory('lib/src/voice');
        expect(voiceDir.existsSync(), isTrue);

        final forbidden = RegExp(
          r'OutboxPort|AuditPort|SyncTransportPort|SyncEngine|'
          r'SharedPreferences|sqlite|drift|http\.|Uri\.parse|'
          r'File\(|Directory\(|stdout\.|print\(|log\(|Logger',
          caseSensitive: false,
        );

        for (final file in voiceDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final source = file.readAsStringSync();
          expect(
            forbidden.hasMatch(source),
            isFalse,
            reason: '${file.path} must not touch persistence/transport/logging',
          );
        }
      },
    );

    test('domain voice exports introduce no Flutter imports', () {
      final voiceDir = Directory('lib/src/voice');
      final flutterImport = RegExp(r'package:flutter/|dart:ui\b');
      for (final file in voiceDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        expect(
          flutterImport.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    });

    test('outbox aggregate kinds remain without a voice entity', () {
      // Guard against accidentally adding a voice sync aggregate name.
      final outbox = File('lib/src/sync/outbox_operation.dart');
      final source = outbox.readAsStringSync().toLowerCase();
      expect(source.contains('voice'), isFalse);
      expect(source.contains('speech'), isFalse);
      expect(source.contains('transcript'), isFalse);
    });
  });
}
