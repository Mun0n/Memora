import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const compactSize = Size(390, 844);
  const desktopSize = Size(1280, 800);

  Future<FamilyWebDemoComposition> pumpWeb(
    WidgetTester tester, {
    required Size size,
    bool seedProfile = true,
    FamilyMembership? actor,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      actor: actor ?? IdentityFixtures.elenaPrimaryMembership,
      networkAvailable: false,
    );
    if (seedProfile) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return composition;
  }

  for (final size in <Size>[compactSize, desktopSize]) {
    final label = size == compactSize ? 'compact' : 'desktop';

    testWidgets('$label: Persona apoyada nav and product chrome are visible', (
      tester,
    ) async {
      await pumpWeb(tester, size: size);

      expect(find.byKey(const Key('memora-brand-title')), findsOneWidget);
      expect(find.text(MemoraCopy.brandTitle), findsWidgets);
      expect(find.textContaining('Family Web'), findsNothing);
      expect(find.text(MemoraCopy.demoBanner), findsNothing);
      expect(find.textContaining('SYNTHETIC'), findsNothing);
      expect(find.text(MemoraCopy.noRealData), findsNothing);
      expect(find.byKey(const Key('memora-sync-status')), findsNothing);

      final profileNav = find.byKey(
        const Key('memora-nav-supported-person-profile'),
      );
      expect(profileNav, findsOneWidget);
      await tester.ensureVisible(profileNav);
      final profileRect = tester.getRect(profileNav);
      expect(profileRect.width, greaterThan(0));
      expect(profileRect.height, greaterThanOrEqualTo(48));
      // Compact layouts may scroll the chip into view horizontally; once
      // visible it must sit inside the viewport without clipping.
      expect(profileRect.left, greaterThanOrEqualTo(-0.5));
      expect(profileRect.right, lessThanOrEqualTo(size.width + 0.5));
      expect(profileRect.top, greaterThanOrEqualTo(-0.5));
      expect(profileRect.bottom, lessThanOrEqualTo(size.height + 0.5));

      await tester.tap(profileNav);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('memora-supported-person-profile')),
        findsOneWidget,
      );
      expect(find.text(MemoraCopy.preferredNameFieldLabel), findsOneWidget);
      expect(find.text('Amparo Demo'), findsWidgets);
    });

    testWidgets(
      '$label: empty profile shows Configurar el nombre CTA on landing',
      (tester) async {
        final composition = await pumpWeb(
          tester,
          size: size,
          seedProfile: false,
        );

        expect(
          composition.supportedPersonProfileController.needsPreferredNameSetup,
          isTrue,
        );
        final cta = find.byKey(
          const Key('memora-configure-preferred-name-cta'),
        );
        expect(cta, findsOneWidget);
        expect(find.text(MemoraCopy.configurePreferredNameCta), findsOneWidget);
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('memora-supported-person-profile')),
          findsOneWidget,
        );
        expect(find.text(MemoraCopy.preferredNameFieldLabel), findsOneWidget);

        composition.supportedPersonProfileController.setDraftPreferredName(
          'Amparo',
        );
        final save = find.byKey(const Key('memora-preferred-name-save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(
          composition.supportedPersonProfileController.profile?.preferredName,
          'Amparo',
        );
        expect(
          composition.supportedPersonProfileController.needsPreferredNameSetup,
          isFalse,
        );
        expect(find.text(MemoraCopy.changesSaved), findsOneWidget);
        // Runtime Amparo is accepted; baseline fixtures stay fictional elsewhere.
        expect(find.text('Amparo Demo'), findsNothing);

        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('routines-after-name-$label'),
            child: composition.buildApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('memora-configure-preferred-name-cta')),
          findsNothing,
        );
      },
    );
  }

  testWidgets('seeded preferred name does not force the landing CTA', (
    tester,
  ) async {
    await pumpWeb(tester, size: compactSize, seedProfile: true);

    expect(
      find.byKey(const Key('memora-configure-preferred-name-cta')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('memora-nav-supported-person-profile')),
      findsOneWidget,
    );
  });

  testWidgets('failed delivery still shows actionable sync recovery chrome', (
    tester,
  ) async {
    tester.view.physicalSize = compactSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(networkAvailable: false);
    await composition.seedDemoFixtures();
    await composition.load();
    composition.supportedPersonProfileController.sharedDeliveryFailed = true;
    await tester.pumpWidget(
      composition.buildApp(
        initialSection: FeatureSection.supportedPersonProfile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-sync-status')), findsOneWidget);
    expect(find.text(MemoraCopy.sharedLocalDemoDeliveryFailed), findsOneWidget);
    expect(
      find.byKey(const Key('memora-sync-recovery-action')),
      findsOneWidget,
    );
  });

  testWidgets('Help shows one medical/emergency limitation notice', (
    tester,
  ) async {
    await pumpWeb(tester, size: compactSize);

    final helpNav = find.byKey(const Key('memora-nav-help'));
    await tester.ensureVisible(helpNav);
    await tester.tap(helpNav);
    await tester.pumpAndSettle();

    final sectionTitle = find.byKey(const Key('memora-section-title'));
    expect(sectionTitle, findsOneWidget);
    expect(tester.widget<Text>(sectionTitle).data, MemoraCopy.helpAboutTitle);
    expect(find.byKey(const Key('memora-help-title')), findsNothing);
    expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
    expect(find.text(MemoraCopy.helpAboutDisclaimer), findsOneWidget);
    expect(find.text(MemoraCopy.notMedical), findsNothing);
    expect(find.textContaining('emergencias'), findsOneWidget);
  });

  testWidgets('Privacy hides fixture ids and audit-implementation copy', (
    tester,
  ) async {
    await pumpWeb(tester, size: compactSize);

    final privacyNav = find.byKey(const Key('memora-nav-privacy'));
    await tester.ensureVisible(privacyNav);
    await tester.tap(privacyNav);
    await tester.pumpAndSettle();

    final sectionTitle = find.byKey(const Key('memora-section-title'));
    expect(sectionTitle, findsOneWidget);
    expect(
      tester.widget<Text>(sectionTitle).data,
      MemoraCopy.privacySectionTitle,
    );
    expect(find.byKey(const Key('memora-privacy-title')), findsNothing);
    expect(find.byKey(const Key('memora-privacy-body')), findsOneWidget);
    expect(find.byKey(const Key('memora-privacy-audit-note')), findsNothing);
    expect(find.text(MemoraCopy.privacyAuditNote), findsNothing);
    expect(find.textContaining('historial auditable'), findsNothing);
    expect(find.text('demo-web'), findsNothing);
    expect(find.text(MemoraCopy.privacyCurrentBrowserSession), findsOneWidget);
  });

  testWidgets('normal pages do not duplicate the selected-section heading', (
    tester,
  ) async {
    await pumpWeb(tester, size: desktopSize);

    Future<void> expectSingleShellHeading(String title) async {
      final sectionTitle = find.byKey(const Key('memora-section-title'));
      expect(sectionTitle, findsOneWidget);
      expect(tester.widget<Text>(sectionTitle).data, title);
      // Removed page-level headline keys must stay gone.
      expect(find.byKey(const Key('memora-privacy-title')), findsNothing);
      expect(find.byKey(const Key('memora-help-title')), findsNothing);
      expect(find.byKey(const Key('memora-sync-title')), findsNothing);
    }

    await expectSingleShellHeading(MemoraCopy.familyHomeTitle);

    Future<void> openNav(Key key) async {
      final nav = find.byKey(key);
      await tester.ensureVisible(nav);
      await tester.tap(nav);
      await tester.pumpAndSettle();
    }

    await openNav(const Key('memora-nav-privacy'));
    await expectSingleShellHeading(MemoraCopy.privacySectionTitle);
    // Longer than the nav chip (`Privacidad`) — exactly one visible heading.
    expect(find.text(MemoraCopy.privacySectionTitle), findsOneWidget);

    await openNav(const Key('memora-nav-sync'));
    await expectSingleShellHeading(MemoraCopy.syncSectionTitle);

    await openNav(const Key('memora-nav-help'));
    await expectSingleShellHeading(MemoraCopy.helpAboutTitle);
    expect(find.text(MemoraCopy.helpAboutTitle), findsOneWidget);

    await openNav(const Key('memora-nav-supported-person-profile'));
    await expectSingleShellHeading(
      MemoraCopy.supportedPersonProfileSectionTitle,
    );
  });
}
