import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<UserDemoComposition> pumpUser(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    bool seed = true,
    FakeSpeechRecognizer? speech,
    FakeSpeechOutput? speechOutput,
    UserHomeDestination initialDestination = UserHomeDestination.home,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      networkAvailable: false,
      speechRecognizer:
          speech ??
          FakeSpeechRecognizer(
            currentPermission: SpeechPermissionStatus.granted,
          ),
      speechOutput: speechOutput ?? FakeSpeechOutput(),
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialDestination: initialDestination),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('phone/tablet @1.0 and 1.5 show ordered topic cards', (
    tester,
  ) async {
    for (final size in [phoneSize, tabletSize]) {
      for (final scale in [1.0, 1.5]) {
        await pumpUser(
          tester,
          size: size,
          textScale: scale,
          initialDestination: UserHomeDestination.quieroHablar,
        );
        expect(
          find.byKey(const Key('memora-user-quiero-hablar')),
          findsOneWidget,
        );
        expect(find.text('El jardín Demo'), findsOneWidget);
        expect(find.textContaining('Cocina Ejemplo'), findsNothing);
        expect(find.textContaining('Música Ejemplo'), findsNothing);
        expect(
          find.byKey(const Key('memora-user-quiero-hablar-pick-for-me')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('empty state is honest and offers return home', (tester) async {
    await pumpUser(
      tester,
      size: phoneSize,
      seed: false,
      initialDestination: UserHomeDestination.quieroHablar,
    );
    expect(
      find.byKey(const Key('memora-user-quiero-hablar-empty')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.quieroHablarEmptyBody), findsOneWidget);
    expect(find.textContaining('acord'), findsNothing);
    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
  });

  testWidgets('offline keeps cached topics selectable without sync jargon', (
    tester,
  ) async {
    // User destinations omit sync chrome; offline honesty is cached usability.
    await pumpUser(
      tester,
      size: phoneSize,
      initialDestination: UserHomeDestination.quieroHablar,
    );
    expect(find.text('El jardín Demo'), findsOneWidget);
    expect(find.textContaining('outbox'), findsNothing);
    expect(find.textContaining('versión'), findsNothing);
    expect(find.textContaining('conflicto'), findsNothing);
    await tester.tap(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-conversation-start')),
      findsOneWidget,
    );
  });

  testWidgets('Elige tú por mí selects the first caregiver-ordered topic', (
    tester,
  ) async {
    await pumpUser(
      tester,
      size: phoneSize,
      initialDestination: UserHomeDestination.quieroHablar,
    );
    await tester.tap(
      find.byKey(const Key('memora-user-quiero-hablar-pick-for-me')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        Key(
          'memora-user-conversation-ready-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('session start speaks then listens; controls and mic release', (
    tester,
  ) async {
    final fake = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.granted,
    );
    fake.enqueue(const SpeechRecognized('Me gustaban las rosas Demo'));
    await pumpUser(
      tester,
      size: phoneSize,
      speech: fake,
      initialDestination: UserHomeDestination.quieroHablar,
    );

    await tester.tap(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memora-user-conversation-start')));
    // Listening banner uses an indeterminate progress indicator — avoid
    // pumpAndSettle; advance past speak pauses + turn chain instead.
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.byKey(const Key('memora-user-conversation-session')),
      findsOneWidget,
    );
    // Auto speak→listen reaches acknowledgement or closing with FakeSpeechOutput.
    expect(
      find.byKey(const Key('memora-user-conversation-displayed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-conversation-mic-released')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.quieroHablarMemoraSpeaking), findsNothing);
    expect(
      find.byKey(const Key('memora-user-conversation-repeat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-conversation-change-topic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-conversation-finish')),
      findsOneWidget,
    );
    expect(fake.releaseCount, greaterThan(0));
  });

  testWidgets('missing local voice shows Hablar and distinct written path', (
    tester,
  ) async {
    final output = FakeSpeechOutput(
      availability: SpeechOutputAvailability.unavailable,
    );
    await pumpUser(
      tester,
      size: phoneSize,
      speechOutput: output,
      initialDestination: UserHomeDestination.quieroHablar,
    );

    await tester.tap(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memora-user-conversation-start')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-conversation-tts-unavailable')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.quieroHablarMemoraSpeaking), findsNothing);
    expect(
      find.text(OfflineFixtures.gardenTalkTopic.introduction),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('memora-user-conversation-continue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-conversation-manual-speak')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.quieroHablarManualSpeak), findsOneWidget);
  });

  testWidgets('targets stay above 48 dp at text scale 1.5', (tester) async {
    await pumpUser(
      tester,
      size: phoneSize,
      textScale: 1.5,
      initialDestination: UserHomeDestination.quieroHablar,
    );
    final pick = tester.getSize(
      find.byKey(const Key('memora-user-quiero-hablar-pick-for-me')),
    );
    expect(pick.height, greaterThan(48));
    final card = tester.getSize(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    expect(card.height, greaterThan(48));
  });

  Future<void> openGardenPromptReady(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    await tester.tap(
      find.byKey(
        Key(
          'memora-user-conversation-topic-'
          '${OfflineFixtures.gardenTalkTopicId.value}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('memora-user-conversation-start')),
    );
    await tester.tap(find.byKey(const Key('memora-user-conversation-start')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('memora-user-conversation-continue')),
    );
    await tester.tap(
      find.byKey(const Key('memora-user-conversation-continue')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectNoHorizontalOverflow(
    WidgetTester tester, {
    required Size viewport,
  }) async {
    expect(tester.takeException(), isNull);
    final session = find.byKey(const Key('memora-user-conversation-session'));
    expect(session, findsOneWidget);
    expect(tester.getSize(session).width, lessThanOrEqualTo(viewport.width));
    final actions = find.byKey(const Key('memora-user-conversation-actions'));
    expect(actions, findsOneWidget);
    expect(tester.getSize(actions).width, lessThanOrEqualTo(viewport.width));
  }

  Future<void> expectHelpExitsHittable(WidgetTester tester) async {
    for (final key in const [
      Key('memora-user-conversation-request-help'),
      Key('memora-user-conversation-repeat'),
      Key('memora-user-conversation-change-topic'),
      Key('memora-user-conversation-finish'),
      Key('memora-user-return-home'),
    ]) {
      final finder = find.byKey(key);
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      expect(tester.getSize(finder).height, greaterThan(48));
    }
  }

  for (final entry in <(String, Size, double)>[
    ('phone 1.0', phoneSize, 1.0),
    ('phone 1.5', phoneSize, 1.5),
    ('tablet 1.0', tabletSize, 1.0),
    ('tablet 1.5', tabletSize, 1.5),
  ]) {
    testWidgets(
      '${entry.$1}: Dame una idea reveal + exits usable, no overflow',
      (tester) async {
        final cue = OfflineFixtures.gardenTalkTopic.prompts[0].help!.cue!;
        final output = FakeSpeechOutput(
          availability: SpeechOutputAvailability.unavailable,
        );
        await pumpUser(
          tester,
          size: entry.$2,
          textScale: entry.$3,
          speechOutput: output,
          initialDestination: UserHomeDestination.quieroHablar,
        );

        await openGardenPromptReady(tester);
        await expectHelpExitsHittable(tester);
        await expectNoHorizontalOverflow(tester, viewport: entry.$2);

        final help = find.byKey(
          const Key('memora-user-conversation-request-help'),
        );
        await tester.ensureVisible(help);
        await tester.tap(help);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('memora-user-conversation-help-reveal')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-conversation-help-cue')),
          findsOneWidget,
        );
        expect(find.text(cue), findsWidgets);
        await tester.ensureVisible(
          find.byKey(const Key('memora-user-conversation-help-cue')),
        );
        await expectHelpExitsHittable(tester);
        await expectNoHorizontalOverflow(tester, viewport: entry.$2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('phone @1.5: linked memory help shows media text fallback', (
    tester,
  ) async {
    final output = FakeSpeechOutput(
      availability: SpeechOutputAvailability.unavailable,
    );
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      networkAvailable: false,
      speechRecognizer: FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      ),
      speechOutput: output,
    );
    await composition.seedDemoFixtures();
    final base = OfflineFixtures.gardenTalkTopic;
    final prompt0 = base.prompts[0];
    await composition.memories.save(
      memory: OfflineFixtures.gardenMemory.copyWith(
        media: OfflineFixtures.gardenMediaFailed,
      ),
      idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
    );
    await composition.conversationTopics.save(
      topic: base.copyWith(
        prompts: <ConversationPrompt>[
          prompt0.copyWith(
            help: ConversationPromptHelp(
              cue: prompt0.help!.cue,
              memoryId: OfflineFixtures.gardenMemoryId,
            ),
          ),
          base.prompts[1],
        ],
      ),
      idempotencyKey: OfflineFixtures.gardenTalkTopicSaveKey,
    );
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(
        initialDestination: UserHomeDestination.quieroHablar,
      ),
    );
    await tester.pumpAndSettle();

    await openGardenPromptReady(tester);
    final help = find.byKey(const Key('memora-user-conversation-request-help'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-conversation-help-reveal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-conversation-help-cue')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        Key(
          'memora-user-conversation-help-memory-'
          '${OfflineFixtures.gardenMemoryId.value}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        Key(
          'memora-user-conversation-help-media-fallback-'
          '${OfflineFixtures.gardenMemoryId.value}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.mediaFailedPlaceholder), findsOneWidget);
    await expectHelpExitsHittable(tester);
    await expectNoHorizontalOverflow(tester, viewport: phoneSize);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'El jardín Demo: one-tap Terminar returns to topic list with mic released',
    (tester) async {
      final output = FakeSpeechOutput();
      final speech = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      await pumpUser(
        tester,
        size: phoneSize,
        speech: speech,
        speechOutput: output,
        initialDestination: UserHomeDestination.quieroHablar,
      );

      await tester.tap(
        find.byKey(
          Key(
            'memora-user-conversation-topic-'
            '${OfflineFixtures.gardenTalkTopicId.value}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('memora-user-conversation-start')));
      await tester.pump();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.byKey(const Key('memora-user-conversation-session')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-user-conversation-finish')),
        findsOneWidget,
      );

      final releaseBefore = output.releaseCount;
      await tester.ensureVisible(
        find.byKey(const Key('memora-user-conversation-finish')),
      );
      await tester.tap(
        find.byKey(const Key('memora-user-conversation-finish')),
      );
      await tester.pumpAndSettle();

      // Automatic return — no second Volver a los temas required.
      expect(
        find.byKey(const Key('memora-user-conversation-session')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('memora-user-conversation-back-topics')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('memora-user-quiero-hablar')),
        findsOneWidget,
      );
      expect(find.text(OfflineFixtures.gardenTalkTopic.title), findsWidgets);
      expect(output.releaseCount, greaterThan(releaseBefore));
      expect(speech.listenCount, greaterThanOrEqualTo(0));
    },
  );

  testWidgets('Terminar with unavailable TTS still returns to topic list', (
    tester,
  ) async {
    final output = FakeSpeechOutput(
      availability: SpeechOutputAvailability.unavailable,
    );
    await pumpUser(
      tester,
      size: phoneSize,
      speechOutput: output,
      initialDestination: UserHomeDestination.quieroHablar,
    );

    await openGardenPromptReady(tester);
    await tester.ensureVisible(
      find.byKey(const Key('memora-user-conversation-finish')),
    );
    await tester.tap(find.byKey(const Key('memora-user-conversation-finish')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-conversation-session')),
      findsNothing,
    );
    expect(find.byKey(const Key('memora-user-quiero-hablar')), findsOneWidget);
  });
}
