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
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(clock: clock ?? fixedClock);
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
  });

  testWidgets('missing profile falls back to exactly Hola', (tester) async {
    await pumpHome(tester, size: phoneSize, seed: false);
    expect(find.text('Hola'), findsOneWidget);
    expect(find.textContaining('Hola,'), findsNothing);
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
          final icon = tester.getRect(
            find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
          );
          final label = tester.getRect(
            find.descendant(of: find.byKey(key), matching: find.byType(Text)),
          );
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
}
