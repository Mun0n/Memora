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
}
