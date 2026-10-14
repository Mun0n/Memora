import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// Caregiver web path from `docs/current/MVP_E2E_SCENARIO.md` (fictional only).
void main() {
  const desktopSize = Size(1280, 800);

  Future<FamilyWebDemoComposition> pumpWeb(
    WidgetTester tester, {
    FeatureSection initialSection = FeatureSection.routines,
  }) async {
    tester.view.physicalSize = desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(networkAvailable: false);
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: initialSection),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('E2E: offline demo — routines, sync push, conflict, privacy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final composition = await pumpWeb(tester);

      expect(composition.sessionBoundary.isDemoOffline, isTrue);
      expect(composition.sessionBoundary.requiresNetwork, isFalse);
      expect(find.textContaining('Rutina de mañana Demo'), findsWidgets);
      expect(find.text(MemoraCopy.demoBanner), findsNothing);
      expect(find.byKey(const Key('memora-brand-title')), findsOneWidget);
      expect(find.byKey(const Key('memora-sync-status')), findsNothing);

      final syncNav = find.byKey(const Key('memora-nav-sync'));
      await tester.ensureVisible(syncNav);
      await tester.tap(syncNav);
      await tester.pumpAndSettle();
      final syncSectionTitle = find.byKey(const Key('memora-section-title'));
      expect(syncSectionTitle, findsOneWidget);
      expect(
        tester.widget<Text>(syncSectionTitle).data,
        MemoraCopy.syncSectionTitle,
      );
      expect(find.byKey(const Key('memora-sync-title')), findsNothing);
      expect(find.text(MemoraCopy.sessionDemoTitle), findsNothing);
      expect(find.byKey(const Key('memora-session-label')), findsNothing);

      await composition.syncController.push();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-sync-feedback')), findsOneWidget);
      expect(find.text(MemoraCopy.changesSaved), findsOneWidget);
      expect(find.byKey(const Key('memora-sync-push-summary')), findsNothing);
      expect(composition.syncController.lastPush, isNotNull);
      expect(composition.syncController.lastPush!.failed, 0);

      await composition.forceRoutineConflict();
      await composition.syncController.push();
      await tester.pumpAndSettle();
      expect(composition.syncController.unresolved, isNotEmpty);
      final conflictId = composition.syncController.unresolved.first.id;
      expect(
        find.byKey(Key('memora-sync-conflict-$conflictId')),
        findsOneWidget,
      );
      expect(find.textContaining('99.9'), findsNothing);
      expect(find.textContaining('kilograms'), findsNothing);

      await composition.syncController.resolve(
        conflictId: conflictId,
        resolution: SyncConflictResolution.keepBoth,
      );
      await tester.pumpAndSettle();
      expect(composition.syncController.unresolved, isEmpty);

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('privacy-shell'),
          child: composition.buildApp(initialSection: FeatureSection.privacy),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-privacy-body')), findsOneWidget);
      expect(find.byKey(const Key('memora-privacy-title')), findsNothing);
      expect(find.byKey(const Key('memora-privacy-audit-note')), findsNothing);
      expect(find.text(MemoraCopy.privacyAuditNote), findsNothing);
      expect(find.text('demo-web'), findsNothing);
      expect(
        find.text(MemoraCopy.privacyCurrentBrowserSession),
        findsOneWidget,
      );
      await composition.privacyController.requestExport();
      await tester.pumpAndSettle();
      expect(find.text(MemoraCopy.privacyExportConfirmed), findsOneWidget);
      await composition.privacyController.requestDeletion();
      await tester.pumpAndSettle();
      expect(find.text(MemoraCopy.privacyDeletionConfirmed), findsOneWidget);
      await composition.privacyController.revokeSession(
        FamilyWebDemoComposition.demoSessionId,
      );
      await tester.pumpAndSettle();
      expect(find.text(MemoraCopy.privacySessionRevoked), findsOneWidget);

      final history = await composition.audit.listForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(
        history.map((e) => e.action),
        containsAll(<String>[
          'export.requested',
          'deletion.requested',
          'session.revoked',
        ]),
      );
      for (final row in history) {
        expect(row.requestId, isNotEmpty);
        expect(row.action.contains('http'), isFalse);
      }

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('help-shell'),
          child: composition.buildApp(initialSection: FeatureSection.help),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-help-title')), findsNothing);
      expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
      expect(find.text(MemoraCopy.helpAboutDisclaimer), findsOneWidget);
      expect(find.text(MemoraCopy.notMedical), findsNothing);
      expect(find.textContaining('emergencias'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('E2E: memories + observations remain reachable offline', (
    tester,
  ) async {
    await pumpWeb(tester, initialSection: FeatureSection.memories);
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-nav-observations')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-observation-disclaimer')),
      findsOneWidget,
    );
    expect(
      find.text(MemoraCopy.observationDisclaimer).evaluate().isNotEmpty,
      isTrue,
    );
    expect(
      MemoraCopy.observationDisclaimer.toLowerCase(),
      isNot(contains('alerta')),
    );
  });

  testWidgets('contributor cannot resolve sync conflicts', (tester) async {
    tester.view.physicalSize = desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      networkAvailable: false,
      actor: IdentityFixtures.luciaContributorMembership,
    );
    await composition.seedDemoFixtures();
    await composition.forceRoutineConflict();
    await composition.syncController.push();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.sync),
    );
    await tester.pumpAndSettle();

    expect(composition.syncController.canResolveConflicts, isFalse);
    expect(find.text(MemoraCopy.syncResolveUnauthorized), findsWidgets);
    expect(find.text(MemoraCopy.syncResolveKeepLocal), findsNothing);
  });
}
