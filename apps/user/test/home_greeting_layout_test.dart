import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);
  final fixedClock = DateTime(2026, 10, 10, 9, 30);

  Future<UserDemoComposition> pumpHome(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    DateTime? clock,
    bool seed = true,
    FakeSpeechOutput? speechOutput,
    FakeSpeechRecognizer? speechRecognizer,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      clock: clock ?? fixedClock,
      speechOutput: speechOutput,
      speechRecognizer: speechRecognizer,
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('greeting shows Hola, Amparo Demo from fictional profile', (
    tester,
  ) async {
    await pumpHome(tester, size: phoneSize);
    expect(find.text('Hola, Amparo Demo'), findsOneWidget);
    expect(find.byKey(const Key('memora-user-home-greeting')), findsOneWidget);
    expect(find.text(MemoraCopy.userHomeInvitation), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-home-invitation')),
      findsOneWidget,
    );
  });

  testWidgets('missing profile falls back to exactly Hola', (tester) async {
    await pumpHome(tester, size: phoneSize, seed: false);
    expect(find.text('Hola'), findsOneWidget);
    expect(find.textContaining('Hola,'), findsNothing);
    expect(find.text(MemoraCopy.userHomeInvitation), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-home-tile-mi-dia')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
  });

  testWidgets('Ayúdame is at least 104 dp on phone layout', (tester) async {
    await pumpHome(tester, size: phoneSize);
    final size = tester.getSize(
      find.byKey(const Key('memora-user-home-ayudame')),
    );
    expect(size.width, greaterThanOrEqualTo(UserHomeGrid.ayudameMinExtent));
    expect(size.height, greaterThanOrEqualTo(UserHomeGrid.ayudameMinExtent));
    expect(size.width, closeTo(size.height, 0.5));
  });

  testWidgets('phone/tablet × 1.0/1.5: tile content centred, no overflow', (
    tester,
  ) async {
    for (final size in [phoneSize, tabletSize]) {
      for (final scale in [1.0, 1.5]) {
        await pumpHome(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsNothing);

        for (final key in [
          const Key('memora-user-home-tile-mi-dia'),
          const Key('memora-user-home-tile-pasatiempos'),
          const Key('memora-user-home-tile-quiero-hablar'),
          const Key('memora-user-home-tile-recuerdos'),
        ]) {
          final tile = tester.getRect(find.byKey(key));
          final iconFinder = find.descendant(
            of: find.byKey(key),
            matching: find.byType(Icon),
          );
          final label = tester.getRect(
            find.descendant(of: find.byKey(key), matching: find.byType(Text)),
          );
          // At large text scales icons may hide so labels keep ≥22 sp.
          if (iconFinder.evaluate().isEmpty) {
            expect(
              (label.center.dx - tile.center.dx).abs(),
              lessThan(12),
              reason: '$key @$size@$scale label not horizontally centred',
            );
            expect(
              (label.center.dy - tile.center.dy).abs(),
              lessThanOrEqualTo(32),
              reason: '$key @$size@$scale label not vertically centred',
            );
            continue;
          }
          final icon = tester.getRect(iconFinder);
          final contentCentreX = (icon.center.dx + label.center.dx) / 2;
          expect(
            (contentCentreX - tile.center.dx).abs(),
            lessThan(12),
            reason: '$key @$size@$scale content not horizontally centred',
          );
          // Midpoint of icon+label; wrapped labels at 1.5× add a few dp of
          // asymmetry vs the true column-group centre (still MainAxisAlignment.center).
          final contentCentreY = (icon.center.dy + label.center.dy) / 2;
          expect(
            (contentCentreY - tile.center.dy).abs(),
            lessThanOrEqualTo(32),
            reason: '$key @$size@$scale content not vertically centred',
          );
        }
      }
    }
  });

  testWidgets('centre Ayúdame tap does not navigate to a tile', (tester) async {
    await pumpHome(tester, size: phoneSize);
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    // Voice panel may open; destinations must not activate from centre tap.
    expect(find.byKey(const Key('memora-user-mi-dia')), findsNothing);
    expect(find.byKey(const Key('memora-user-pastimes')), findsNothing);
  });

  testWidgets('five actions exceed 48 dp with distinct semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpHome(tester, size: phoneSize);
      for (final key in [
        const Key('memora-user-home-tile-mi-dia'),
        const Key('memora-user-home-tile-pasatiempos'),
        const Key('memora-user-home-tile-quiero-hablar'),
        const Key('memora-user-home-tile-recuerdos'),
        const Key('memora-user-home-ayudame'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThan(48));
        expect(size.height, greaterThan(48));
      }
      expect(
        find.bySemanticsLabel(MemoraCopy.homeAyudameSemantics),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'fixed clock only when injected; live composition uses null clock',
    (tester) async {
      final live = UserDemoComposition(enableLiveOrientation: true);
      expect(live.controller.usesLiveClock, isTrue);
      expect(live.enableLiveOrientation, isTrue);

      final fixed = UserDemoComposition(clock: fixedClock);
      expect(fixed.controller.usesLiveClock, isFalse);
      expect(
        fixed.controller.orientationLabel,
        contains('10 de octubre de 2026'),
      );
    },
  );

  testWidgets('orientation refresh does not reset navigation', (tester) async {
    final composition = await pumpHome(tester, size: phoneSize);
    await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);

    composition.controller.refreshOrientation();
    await tester.pump();
    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-home')), findsNothing);
  });

  testWidgets('tile quadrant centre still opens destination', (tester) async {
    await pumpHome(tester, size: phoneSize);
    final miDiaCentre = tester
        .getRect(find.byKey(const Key('memora-user-home-tile-mi-dia')))
        .center;
    await tester.tapAt(miDiaCentre);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);
  });

  testWidgets(
    'launch speaks greeting then invitation once without opening mic',
    (tester) async {
      final output = FakeSpeechOutput(autoComplete: false);
      final recognizer = FakeSpeechRecognizer(
        currentPermission: SpeechPermissionStatus.granted,
      );
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final composition = UserDemoComposition(
        clock: fixedClock,
        speechOutput: output,
        speechRecognizer: recognizer,
      );
      await composition.seedDemoFixtures();
      await composition.load();
      await tester.pumpWidget(composition.buildApp());
      await tester.pump(); // post-frame scheduling
      await tester.pump(); // greeting speak starts

      expect(find.text('Hola, Amparo Demo'), findsOneWidget);
      expect(output.retainedUtteranceForTest, 'Hola, Amparo Demo');
      expect(recognizer.listenCount, 0);
      expect(recognizer.requestPermissionCount, 0);

      output.completeCurrent();
      await tester.pump();
      expect(output.retainedUtteranceForTest, MemoraCopy.userHomeInvitation);
      expect(recognizer.listenCount, 0);

      output.completeCurrent();
      await tester.pump();
      expect(output.speakCount, 2);
      expect(recognizer.listenCount, 0);

      // Actions remain hittable while/after spoken greeting.
      expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
      await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);

      // Return home must not re-speak.
      final speaksBeforeReturn = output.speakCount;
      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
      expect(output.speakCount, speaksBeforeReturn);
    },
  );

  testWidgets('missing profile speaks exactly Hola then invitation', (
    tester,
  ) async {
    final output = FakeSpeechOutput(autoComplete: false);
    final recognizer = FakeSpeechRecognizer(
      currentPermission: SpeechPermissionStatus.granted,
    );
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = UserDemoComposition(
      clock: fixedClock,
      speechOutput: output,
      speechRecognizer: recognizer,
    );
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget);
    expect(output.retainedUtteranceForTest, 'Hola');
    output.completeCurrent();
    await tester.pump();
    expect(output.retainedUtteranceForTest, MemoraCopy.userHomeInvitation);
    output.completeCurrent();
    await tester.pump();
    expect(recognizer.listenCount, 0);
  });

  testWidgets('unavailable TTS leaves visual home usable without trap', (
    tester,
  ) async {
    final output = FakeSpeechOutput(
      availability: SpeechOutputAvailability.unavailable,
    );
    await pumpHome(tester, size: phoneSize, speechOutput: output);
    expect(find.text('Hola, Amparo Demo'), findsOneWidget);
    expect(find.text(MemoraCopy.userHomeInvitation), findsOneWidget);
    expect(output.speakCount, 0);
    expect(find.byKey(const Key('memora-user-home-ayudame')), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);
  });
}
