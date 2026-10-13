import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<({UserDemoComposition composition, FakeSpeechRecognizer fake})>
  pumpUser(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    FakeSpeechRecognizer? speech,
    bool networkAvailable = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final fake =
        speech ??
        FakeSpeechRecognizer(currentPermission: SpeechPermissionStatus.granted);
    final composition = UserDemoComposition(
      networkAvailable: networkAvailable,
      speechRecognizer: fake,
    );
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return (composition: composition, fake: fake);
  }

  Future<void> expectNoHomeOverflow(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
  }

  testWidgets('AC1 phone/tablet 1.0 & 1.5: four tiles + Ayúdame, no overflow', (
    tester,
  ) async {
    for (final size in [phoneSize, tabletSize]) {
      for (final scale in [1.0, 1.5]) {
        await pumpUser(tester, size: size, textScale: scale);
        expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
        expect(
          find.byKey(const Key('memora-user-home-tile-mi-dia')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-pasatiempos')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-recuerdos')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-ayudame')),
          findsOneWidget,
        );
        expect(find.text(MemoraCopy.homeAyudameLabel), findsOneWidget);
        await expectNoHomeOverflow(tester);
      }
    }
  });

  testWidgets('AC2 five distinct ≥48 dp actions with Spanish semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(tester, size: phoneSize);
      final keys = [
        const Key('memora-user-home-tile-mi-dia'),
        const Key('memora-user-home-tile-pasatiempos'),
        const Key('memora-user-home-tile-quiero-hablar'),
        const Key('memora-user-home-tile-recuerdos'),
        const Key('memora-user-home-ayudame'),
      ];
      final rects = <Rect>[];
      for (final key in keys) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThan(48));
        expect(size.height, greaterThan(48));
        rects.add(tester.getRect(find.byKey(key)));
      }
      // Ayúdame centre must not share the same origin as any tile.
      final ayudame = rects.last;
      for (var i = 0; i < 4; i++) {
        expect(
          rects[i].center == ayudame.center,
          isFalse,
          reason: 'tile $i shares centre with Ayúdame',
        );
      }
      expect(find.bySemanticsLabel(MemoraCopy.homeTileMiDia), findsOneWidget);
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTilePasatiempos),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTileQuieroHablar),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTileRecuerdos),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(MemoraCopy.homeAyudameSemantics),
        findsOneWidget,
      );

      // Keyboard-style activation via semantics actions.
      final ayudameNode = tester.getSemantics(
        find.byKey(const Key('memora-user-home-ayudame')),
      );
      expect(ayudameNode.flagsCollection.isButton, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('AC3 no listen before tap; mic released on cancel', (
    tester,
  ) async {
    final pumped = await pumpUser(tester, size: phoneSize);
    expect(pumped.fake.listenCount, 0);

    pumped.fake.enqueue(const SpeechRecognized('quiero una actividad'));
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(pumped.fake.listenCount, 1);
    expect(find.byKey(const Key('memora-user-voice-panel')), findsOneWidget);
    expect(find.text(MemoraCopy.voiceSuggestPasatiempos), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-user-voice-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-voice-panel')), findsNothing);
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    expect(pumped.fake.releaseCount, greaterThan(0));
    expect(pumped.fake.isListening, isFalse);
  });

  testWidgets('AC3 permission explain before first mic request', (
    tester,
  ) async {
    final fake = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.notDetermined,
    );
    await pumpUser(tester, size: phoneSize, speech: fake);

    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(fake.listenCount, 0);
    expect(fake.requestPermissionCount, 0);
    expect(find.text(MemoraCopy.voicePermissionExplain), findsOneWidget);

    fake.enqueue(const SpeechRecognized('qué tengo que hacer'));
    await tester.tap(find.byKey(const Key('memora-user-voice-continue')));
    await tester.pumpAndSettle();

    expect(fake.requestPermissionCount, 1);
    expect(fake.listenCount, 1);
    expect(find.text(MemoraCopy.voiceSuggestMiDia), findsOneWidget);
  });

  testWidgets('AC4 unavailable recognizer recovers to manual home', (
    tester,
  ) async {
    final fake = FakeSpeechRecognizer(
      availability: SpeechRecognizerAvailability.languagePackMissing,
      currentPermission: SpeechPermissionStatus.granted,
    );
    await pumpUser(tester, size: phoneSize, speech: fake);

    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(fake.listenCount, 0);
    expect(find.text(MemoraCopy.voiceRecognizerUnavailable), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-voice-manual')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-home-tile-mi-dia')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
  });

  testWidgets('AC7 confirm-before-nav; recognition alone never navigates', (
    tester,
  ) async {
    final pumped = await pumpUser(tester, size: phoneSize);
    pumped.fake.enqueue(const SpeechRecognized('quiero ver fotos'));
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(find.text(MemoraCopy.voiceSuggestRecuerdos), findsOneWidget);
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-recuerdos')), findsNothing);

    await tester.tap(find.byKey(const Key('memora-user-voice-go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-recuerdos')), findsOneWidget);
  });

  testWidgets('AC7 silence and timeout never trap', (tester) async {
    final fake = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.granted,
    );
    fake.enqueue(const SpeechSilence());
    await pumpUser(tester, size: phoneSize, speech: fake);

    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    expect(find.text(MemoraCopy.voiceSilence), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-voice-manual')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);

    fake.enqueue(const SpeechTimeout());
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    expect(find.text(MemoraCopy.voiceTimeout), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-voice-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
  });

  testWidgets('AC7 permission denial never traps manual tiles', (tester) async {
    final denied = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.denied,
    );
    await pumpUser(tester, size: phoneSize, speech: denied);
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    expect(find.text(MemoraCopy.voicePermissionDenied), findsOneWidget);
    expect(denied.listenCount, 0);
    await tester.tap(find.byKey(const Key('memora-user-voice-manual')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      findsOneWidget,
    );
  });

  testWidgets('AC9 Quiero hablar suggestion stays honest; tiles still work', (
    tester,
  ) async {
    final pumped = await pumpUser(tester, size: phoneSize);
    pumped.fake.enqueue(const SpeechRecognized('quiero llamar'));
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(find.textContaining('no se hace ninguna llamada'), findsOneWidget);
    expect(find.textContaining('emergencia'), findsNothing);
    await tester.tap(find.byKey(const Key('memora-user-voice-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-quiero-hablar')), findsOneWidget);
  });

  testWidgets('recognized phrase is visible only during the result flow', (
    tester,
  ) async {
    final secret = 'frase secreta de prueba 42';
    final pumped = await pumpUser(tester, size: phoneSize);
    pumped.fake.enqueue(SpeechRecognized(secret));
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();

    expect(find.text(secret), findsOneWidget);
    expect(find.text(MemoraCopy.voiceUnderstood), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-voice-cancel')));
    await tester.pumpAndSettle();
    expect(find.text(secret), findsNothing);
  });

  testWidgets('centre Ayúdame hit wins over tile stack; tiles remain usable', (
    tester,
  ) async {
    final pumped = await pumpUser(tester, size: phoneSize);
    expect(pumped.fake.listenCount, 0);

    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    // Default empty fake queue → timeout outcome.
    expect(find.byKey(const Key('memora-user-voice-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-voice-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);
  });

  testWidgets('sync failure does not move five home controls', (tester) async {
    final failedStore = InMemoryOfflineStore();
    failedStore.putRoutine(OfflineFixtures.morningRoutine);
    failedStore.putProgress(
      OfflineFixtures.morningProgressPending.copyWith(
        syncState: SyncState.failed,
      ),
    );
    final fake = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.granted,
    );
    final composition = UserDemoComposition(
      store: failedStore,
      networkAvailable: true,
      speechRecognizer: fake,
    );
    await composition.load();
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-home-tile-mi-dia')),
      findsOneWidget,
    );
    expect(find.textContaining('conflicto'), findsNothing);
  });
}
