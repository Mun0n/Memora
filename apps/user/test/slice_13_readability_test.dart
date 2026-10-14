import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phone390 = Size(390, 844);
  const phone360 = Size(360, 800);
  const tablet = Size(800, 1280);
  final fixedClock = DateTime(2026, 10, 10, 9, 30);

  Future<UserDemoComposition> pumpHome(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    bool seed = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(clock: fixedClock);
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return composition;
  }

  double? styleFontSize(WidgetTester tester, Finder finder) {
    final text = tester.widget<Text>(finder);
    return text.style?.fontSize;
  }

  test('supported-person typography minima; caregiver light unchanged', () {
    final user = MemoraTheme.supportedPerson().textTheme;
    expect(
      user.bodyMedium?.fontSize,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.secondary),
    );
    expect(
      user.bodyLarge?.fontSize,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.body),
    );
    expect(
      user.titleLarge?.fontSize,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.title),
    );
    expect(
      user.headlineSmall?.fontSize,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.heading),
    );
    expect(
      user.labelSmall?.fontSize,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.ayudame),
    );
    expect(
      user.bodyLarge?.height,
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.bodyHeight),
    );

    final caregiver = MemoraTheme.light().textTheme;
    final material = Typography.material2021().black;
    expect(caregiver.bodyLarge?.fontSize, material.bodyLarge?.fontSize);
    expect(caregiver.headlineSmall?.fontSize, material.headlineSmall?.fontSize);
    expect(caregiver.titleLarge?.fontSize, material.titleLarge?.fontSize);
  });

  testWidgets('user MaterialApp hides DEBUG ribbon (AC1)', (tester) async {
    await pumpHome(tester, size: phone390);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(find.textContaining('DEBUG'), findsNothing);
    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('greeting → invitation → orientation hierarchy (AC2/AC3)', (
    tester,
  ) async {
    await pumpHome(tester, size: phone390);

    expect(find.text('Hola, Amparo Demo'), findsOneWidget);
    expect(find.text(MemoraCopy.userHomeInvitation), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-home-invitation')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(Tooltip), findsNothing);

    final greetingTop = tester
        .getTopLeft(find.byKey(const Key('memora-user-home-greeting')))
        .dy;
    final invitationTop = tester
        .getTopLeft(find.byKey(const Key('memora-user-home-invitation')))
        .dy;
    final orientationTop = tester
        .getTopLeft(find.byKey(const Key('memora-user-orientation')))
        .dy;
    final miDiaTop = tester
        .getTopLeft(find.byKey(const Key('memora-user-home-tile-mi-dia')))
        .dy;

    expect(greetingTop, lessThan(invitationTop));
    expect(invitationTop, lessThan(orientationTop));
    expect(orientationTop, lessThan(miDiaTop));

    expect(
      styleFontSize(tester, find.byKey(const Key('memora-user-home-greeting'))),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.heading),
    );
    expect(
      styleFontSize(
        tester,
        find.byKey(const Key('memora-user-home-invitation')),
      ),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.secondary),
    );
    expect(
      styleFontSize(tester, find.byKey(const Key('memora-user-orientation'))),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.secondary),
    );
    expect(
      styleFontSize(
        tester,
        find.descendant(
          of: find.byKey(const Key('memora-user-home-tile-mi-dia')),
          matching: find.byType(Text),
        ),
      ),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.title),
    );
    expect(
      styleFontSize(
        tester,
        find.descendant(
          of: find.byKey(const Key('memora-user-home-ayudame')),
          matching: find.byType(Text),
        ),
      ),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.ayudame),
    );
  });

  testWidgets('missing profile: Hola + same invitation', (tester) async {
    await pumpHome(tester, size: phone390, seed: false);
    expect(find.text('Hola'), findsOneWidget);
    expect(find.textContaining('Hola,'), findsNothing);
    expect(find.text(MemoraCopy.userHomeInvitation), findsOneWidget);
  });

  testWidgets('semantics announce intro before five actions', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpHome(tester, size: phone390);
      final nodes = <String>[];
      void walk(SemanticsNode node) {
        final data = node.getSemanticsData();
        final label = data.label;
        if (label.isNotEmpty) {
          nodes.add(label);
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      final root = tester
          .binding
          // ignore: deprecated_member_use -- WidgetTester semantics still live here.
          .pipelineOwner
          .semanticsOwner!
          .rootSemanticsNode!;
      walk(root);

      final greetingIdx = nodes.indexWhere((l) => l.contains('Hola'));
      final invitationIdx = nodes.indexWhere(
        (l) => l.contains(MemoraCopy.userHomeInvitation),
      );
      final orientationIdx = nodes.indexWhere(
        (l) => l.contains('octubre') || l.contains('2026'),
      );
      final miDiaIdx = nodes.indexOf(MemoraCopy.homeTileMiDia);
      final ayudameIdx = nodes.indexOf(MemoraCopy.homeAyudameSemantics);

      expect(greetingIdx, greaterThanOrEqualTo(0));
      expect(invitationIdx, greaterThan(greetingIdx));
      expect(orientationIdx, greaterThan(invitationIdx));
      expect(miDiaIdx, greaterThan(orientationIdx));
      expect(ayudameIdx, greaterThan(orientationIdx));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('home layouts: 390/360/tablet × text scales without scroll', (
    tester,
  ) async {
    final cases = <(Size, double)>[
      (phone390, 1.0),
      (phone390, 1.3),
      (phone390, 1.5),
      (phone360, 1.0),
      (phone360, 1.3),
      (tablet, 1.0),
      (tablet, 1.5),
    ];

    for (final entry in cases) {
      await pumpHome(tester, size: entry.$1, textScale: entry.$2);
      expect(
        tester.takeException(),
        isNull,
        reason: 'exception @${entry.$1}@${entry.$2}',
      );
      expect(
        find.byType(Scrollable),
        findsNothing,
        reason: 'home scroll @${entry.$1}@${entry.$2}',
      );

      for (final key in [
        const Key('memora-user-home-greeting'),
        const Key('memora-user-home-invitation'),
        const Key('memora-user-orientation'),
        const Key('memora-user-home-tile-mi-dia'),
        const Key('memora-user-home-tile-pasatiempos'),
        const Key('memora-user-home-tile-quiero-hablar'),
        const Key('memora-user-home-tile-recuerdos'),
        const Key('memora-user-home-ayudame'),
      ]) {
        expect(
          find.byKey(key),
          findsOneWidget,
          reason: '$key @${entry.$1}@${entry.$2}',
        );
        final textFinder = find.descendant(
          of: find.byKey(key),
          matching: find.byType(Text),
        );
        if (textFinder.evaluate().isNotEmpty) {
          final text = tester.widget<Text>(textFinder.first);
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: 'ellipsis on $key @${entry.$1}@${entry.$2}',
          );
        }
      }

      final ayudame = tester.getSize(
        find.byKey(const Key('memora-user-home-ayudame')),
      );
      expect(
        ayudame.width,
        greaterThanOrEqualTo(UserHomeGrid.ayudameMinExtent),
      );
      expect(
        ayudame.height,
        greaterThanOrEqualTo(UserHomeGrid.ayudameMinExtent),
      );

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

      // Non-overlapping tile hit regions (quadrant centres distinct from Ayúdame).
      final ayRect = tester.getRect(
        find.byKey(const Key('memora-user-home-ayudame')),
      );
      final miDia = tester.getRect(
        find.byKey(const Key('memora-user-home-tile-mi-dia')),
      );
      expect(miDia.center.dx, isNot(closeTo(ayRect.center.dx, 8)));
    }
  });

  testWidgets('destinations usable on 360×800 at 1.5 with scroll allowed', (
    tester,
  ) async {
    await pumpHome(tester, size: phone360, textScale: 1.5);

    Future<void> openAndCheck(Key tileKey, Key destinationKey) async {
      await tester.tap(find.byKey(tileKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.byKey(const Key('memora-user-return-home')), findsOneWidget);

      final headings = find.descendant(
        of: find.byKey(destinationKey),
        matching: find.byType(Text),
      );
      expect(headings, findsWidgets);
      final first = tester.widget<Text>(headings.first);
      expect(
        first.style?.fontSize ?? 0,
        greaterThanOrEqualTo(MemoraSupportedPersonTypography.heading),
      );

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    }

    await openAndCheck(
      const Key('memora-user-home-tile-mi-dia'),
      const Key('memora-user-mi-dia'),
    );
    await openAndCheck(
      const Key('memora-user-home-tile-pasatiempos'),
      const Key('memora-user-pasatiempos'),
    );
    await openAndCheck(
      const Key('memora-user-home-tile-quiero-hablar'),
      const Key('memora-user-quiero-hablar'),
    );
    await openAndCheck(
      const Key('memora-user-home-tile-recuerdos'),
      const Key('memora-user-recuerdos'),
    );
  });

  testWidgets('voice panel essential copy meets heading/body scale', (
    tester,
  ) async {
    await pumpHome(tester, size: phone360, textScale: 1.5);
    await tester.tap(find.byKey(const Key('memora-user-home-ayudame')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-voice-panel')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-voice-message')), findsOneWidget);
    expect(
      styleFontSize(tester, find.byKey(const Key('memora-user-voice-message'))),
      greaterThanOrEqualTo(MemoraSupportedPersonTypography.heading),
    );
    expect(tester.takeException(), isNull);
  });
}
