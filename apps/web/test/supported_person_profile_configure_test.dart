import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  Future<FamilyWebDemoComposition> pumpProfile(
    WidgetTester tester, {
    FamilyMembership? actor,
  }) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      actor: actor ?? IdentityFixtures.elenaPrimaryMembership,
      networkAvailable: false,
    );
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(
        initialSection: FeatureSection.supportedPersonProfile,
      ),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('primary can create and correct Nombre que verá en Memora', (
    tester,
  ) async {
    final composition = await pumpProfile(tester);

    expect(
      find.byKey(const Key('memora-supported-person-profile')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.preferredNameFieldLabel), findsOneWidget);
    expect(find.text('Amparo Demo'), findsWidgets);
    expect(find.byKey(const Key('memora-preferred-name-save')), findsOneWidget);

    composition.supportedPersonProfileController.setDraftPreferredName(
      'Amparo Ejemplo',
    );
    final save = find.byKey(const Key('memora-preferred-name-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      composition.supportedPersonProfileController.profile?.preferredName,
      'Amparo Ejemplo',
    );
    expect(find.text('Amparo Ejemplo'), findsWidgets);
    expect(find.byKey(const Key('memora-preferred-name-error')), findsNothing);
    expect(find.text(MemoraCopy.changesSaved), findsOneWidget);
    expect(
      find.byKey(const Key('memora-preferred-name-saved')),
      findsOneWidget,
    );
  });

  testWidgets('invalid input preserves saved preferred name', (tester) async {
    final composition = await pumpProfile(tester);
    final saved =
        composition.supportedPersonProfileController.profile!.preferredName;

    composition.supportedPersonProfileController.setDraftPreferredName('   ');
    await composition.supportedPersonProfileController.savePreferredName();
    await tester.pumpAndSettle();

    expect(
      composition.supportedPersonProfileController.profile?.preferredName,
      saved,
    );
    expect(
      find.byKey(const Key('memora-preferred-name-error')),
      findsOneWidget,
    );
    expect(
      find.text(MemoraCopy.supportedPersonProfileValidationError),
      findsOneWidget,
    );
  });

  testWidgets('ordinary caregiver cannot mutate preferred name via UI', (
    tester,
  ) async {
    final composition = await pumpProfile(
      tester,
      actor: IdentityFixtures.carlosCaregiverMembership,
    );

    expect(
      find.byKey(const Key('memora-supported-person-profile-read-only')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-preferred-name-save')), findsNothing);
    expect(composition.supportedPersonProfileController.canEdit, isFalse);

    composition.supportedPersonProfileController.setDraftPreferredName(
      'Nombre Prohibido Demo',
    );
    await composition.supportedPersonProfileController.savePreferredName();
    await tester.pumpAndSettle();

    expect(
      composition.supportedPersonProfileController.profile?.preferredName,
      IdentityFixtures.amparoSupportedDisplayName,
    );
    expect(
      find.text(MemoraCopy.supportedPersonProfileUnauthorized),
      findsOneWidget,
    );
  });

  testWidgets('contributor cannot view or mutate preferred name', (
    tester,
  ) async {
    final composition = await pumpProfile(
      tester,
      actor: IdentityFixtures.luciaContributorMembership,
    );

    expect(
      find.byKey(const Key('memora-supported-person-profile-denied')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-preferred-name-field')), findsNothing);
    expect(composition.supportedPersonProfileController.canView, isFalse);
    expect(composition.supportedPersonProfileController.canEdit, isFalse);
  });
}
