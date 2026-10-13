import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('VoiceIntentMatcher', () {
    test('normalizes accents and punctuation', () {
      expect(
        VoiceIntentMatcher.normalize('  ¡Qué Tengo Que Hacer!  '),
        'que tengo que hacer',
      );
      expect(VoiceIntentMatcher.normalize(null), isEmpty);
    });

    test('empty or whitespace is unclear', () {
      expect(VoiceIntentMatcher.classify(null), VoiceIntentClass.unclear);
      expect(VoiceIntentMatcher.classify(''), VoiceIntentClass.unclear);
      expect(VoiceIntentMatcher.classify(' \t '), VoiceIntentClass.unclear);
    });
  });

  group('VoiceRecommendationPolicy table-driven fixtures', () {
    for (final fixture in VoiceUtteranceFixtures.all) {
      test('${fixture.id}: "${fixture.utterance}"', () {
        final intent = VoiceIntentMatcher.classify(fixture.utterance);
        expect(intent, fixture.expectedIntent, reason: 'intent class');

        final decision = VoiceRecommendationPolicy.recommend(
          textInMemory: fixture.utterance,
          content: fixture.content,
        );

        expect(decision.kind, fixture.expectedKind);
        expect(decision.intent, fixture.expectedIntent);
        expect(decision.destination, fixture.expectedDestination);
        expect(
          decision.usesTalkPlaceholderWording,
          fixture.expectTalkPlaceholder,
        );

        switch (fixture.expectedKind) {
          case VoiceGuidanceKind.suggestDestination:
            expect(decision.suggestsDestination, isTrue);
            expect(decision.destination, isNotNull);
            expect(
              decision.message,
              VoiceGuidanceCopy.suggestDestination(decision.destination!),
            );
            if (fixture.expectTalkPlaceholder) {
              expect(decision.message, VoiceGuidanceCopy.suggestQuieroHablar);
              expect(
                decision.message.toLowerCase(),
                allOf(
                  contains('no se hace ninguna llamada'),
                  contains('conversar'),
                ),
              );
              expect(decision.usesTalkHonestyWording, isTrue);
            }
          case VoiceGuidanceKind.unclear:
            expect(decision.message, VoiceGuidanceCopy.unclear);
            expect(decision.destination, isNull);
          case VoiceGuidanceKind.nothingPrepared:
            expect(decision.message, VoiceGuidanceCopy.nothingPrepared);
            expect(decision.destination, isNull);
          case VoiceGuidanceKind.safetyLimitation:
            expect(decision.message, VoiceGuidanceCopy.safetyLimitation);
            expect(decision.destination, isNull);
            expect(
              decision.message.toLowerCase(),
              allOf(
                contains('no es un servicio médico'),
                contains('emergencias'),
              ),
            );
        }
      });
    }
  });

  group('VoiceRecommendationPolicy generic priority', () {
    test('never selects Quiero hablar for generic help', () {
      const content = VoiceContentSnapshot(
        hasCurrentOrPendingMiDia: false,
        hasActivePastimes: false,
        hasApprovedMemories: false,
        hasActiveConversationTopics: true,
      );
      final decision = VoiceRecommendationPolicy.recommend(
        textInMemory: 'No sé qué hacer',
        content: content,
      );
      expect(decision.kind, VoiceGuidanceKind.nothingPrepared);
      expect(decision.destination, isNot(HomeGuidanceDestination.quieroHablar));

      // Active topics must not cause generic help to profile conversation need.
      final withEverything = VoiceRecommendationPolicy.forIntent(
        intent: VoiceIntentClass.genericHelp,
        content: VoiceContentSnapshot.allAvailable,
      );
      expect(
        withEverything.destination,
        isNot(HomeGuidanceDestination.quieroHablar),
      );
      expect(withEverything.destination, HomeGuidanceDestination.miDia);
    });

    test('explicit talk requires cached active topics', () {
      final available = VoiceRecommendationPolicy.forIntent(
        intent: VoiceIntentClass.explicitTalk,
        content: const VoiceContentSnapshot(
          hasCurrentOrPendingMiDia: false,
          hasActivePastimes: false,
          hasApprovedMemories: false,
          hasActiveConversationTopics: true,
        ),
      );
      expect(available.destination, HomeGuidanceDestination.quieroHablar);

      final unavailable = VoiceRecommendationPolicy.forIntent(
        intent: VoiceIntentClass.explicitTalk,
        content: VoiceContentSnapshot.empty,
      );
      expect(unavailable.kind, VoiceGuidanceKind.nothingPrepared);
      expect(unavailable.destination, isNull);
    });

    test('skips unavailable steps in priority order', () {
      final pastimes = VoiceRecommendationPolicy.forIntent(
        intent: VoiceIntentClass.genericHelp,
        content: const VoiceContentSnapshot(
          hasCurrentOrPendingMiDia: false,
          hasActivePastimes: true,
          hasApprovedMemories: true,
        ),
      );
      expect(pastimes.destination, HomeGuidanceDestination.pasatiempos);

      final memories = VoiceRecommendationPolicy.forIntent(
        intent: VoiceIntentClass.genericHelp,
        content: const VoiceContentSnapshot(
          hasCurrentOrPendingMiDia: false,
          hasActivePastimes: false,
          hasApprovedMemories: true,
        ),
      );
      expect(memories.destination, HomeGuidanceDestination.recuerdos);
    });
  });

  group('VoiceRecommendationPolicy safety', () {
    test('safety language never yields a destination', () {
      for (final utterance in <String>[
        'Llama a emergencias',
        'Me duele el pecho',
        'Necesito una ambulancia',
        '¿Qué medicina tomo?',
      ]) {
        final decision = VoiceRecommendationPolicy.recommend(
          textInMemory: utterance,
          content: VoiceContentSnapshot.allAvailable,
        );
        expect(decision.kind, VoiceGuidanceKind.safetyLimitation);
        expect(decision.destination, isNull);
        expect(decision.suggestsDestination, isFalse);
      }
    });
  });

  group('VoiceGuidanceCopy', () {
    test('go-to labels cover all four destinations', () {
      for (final destination in HomeGuidanceDestination.values) {
        expect(VoiceGuidanceCopy.goToLabel(destination), startsWith('Ir a '));
        expect(
          VoiceGuidanceCopy.suggestDestination(destination),
          startsWith('Te recomiendo '),
        );
      }
    });
  });
}
