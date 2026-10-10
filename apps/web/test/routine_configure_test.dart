import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);
  const desktopSize = Size(1280, 800);

  Future<FamilyWebDemoComposition> pumpWeb(
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

    final composition = FamilyWebDemoComposition(networkAvailable: false);
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('narrow: caregiver creates and edits a Demo routine', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpWeb(tester, size: narrowSize, seed: false);

      expect(
        find.bySemanticsLabel(
          'Memora Family Web shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Compact shell layout'), findsOneWidget);
      expect(find.textContaining('Familia Ejemplo'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-reminder-convenience-notice')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('memora-family-routine-title')),
        'Rutina nueva Demo',
      );
      await tester.enterText(
        find.byKey(const Key('memora-family-step-0')),
        'Paso uno Ejemplo',
      );
      final save = find.byKey(const Key('memora-family-save-routine'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.textContaining('Rutina nueva Demo'), findsWidgets);

      final editButton = find.text(MemoraCopy.editRoutine);
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('memora-family-routine-title')),
        'Rutina editada Demo',
      );
      await tester.enterText(
        find.byKey(const Key('memora-family-step-0')),
        'Paso editado Ejemplo',
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.textContaining('Rutina editada Demo'), findsWidgets);
      expect(find.textContaining('Paso editado Ejemplo'), findsWidgets);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('desktop: activate/archive and quiet-hours reminder copy', (
    tester,
  ) async {
    await pumpWeb(tester, size: desktopSize);

    expect(find.bySemanticsLabel('Expanded shell layout'), findsOneWidget);
    expect(find.textContaining('Rutina de mañana Demo'), findsOneWidget);
    expect(find.textContaining('archivada'), findsWidgets);
    expect(find.textContaining('Paseo corto Demo'), findsOneWidget);
    expect(find.textContaining('avisos de comodidad'), findsWidgets);
    expect(find.textContaining('emergencia'), findsWidgets);

    final archive = find.byKey(
      Key('memora-family-archive-${OfflineFixtures.morningRoutineId.value}'),
    );
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    await tester.pumpAndSettle();

    final activate = find.byKey(
      Key('memora-family-activate-${OfflineFixtures.morningRoutineId.value}'),
    );
    expect(activate, findsOneWidget);
    await tester.ensureVisible(activate);
    await tester.tap(activate);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        Key('memora-family-archive-${OfflineFixtures.morningRoutineId.value}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('narrow text scale 1.3 keeps configure copy readable', (
    tester,
  ) async {
    await pumpWeb(tester, size: narrowSize, textScale: 1.3);
    expect(find.textContaining('Rutinas y recordatorios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save routine button meets large touch target', (tester) async {
    await pumpWeb(tester, size: narrowSize);
    final save = find.byKey(const Key('memora-family-save-routine'));
    expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
  });

  testWidgets('empty offline recovery offers create routine', (tester) async {
    await pumpWeb(tester, size: narrowSize, seed: false);
    expect(find.byKey(const Key('memora-family-empty')), findsOneWidget);
    expect(find.text(MemoraCopy.recoveryCreateRoutine), findsOneWidget);
    final recovery = find.byKey(const Key('memora-sync-recovery-action'));
    await tester.ensureVisible(recovery);
    await tester.tap(recovery);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-family-routine-editor')),
      findsOneWidget,
    );
  });

  testWidgets('shared contract: seeded morning routine title visible', (
    tester,
  ) async {
    final composition = await pumpWeb(tester, size: desktopSize);
    final listed = await composition.routines.listActiveForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(listed.single.title, OfflineFixtures.morningRoutine.title);
    expect(find.textContaining(listed.single.title), findsWidgets);
  });
}
