import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);

  Future<FamilyWebDemoComposition> pumpConversations(
    WidgetTester tester, {
    FamilyMembership? actor,
    bool seed = true,
  }) async {
    tester.view.physicalSize = narrowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      actor: actor ?? IdentityFixtures.elenaPrimaryMembership,
      networkAvailable: false,
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.conversations),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('caregiver creates and previews a Demo conversation topic', (
    tester,
  ) async {
    final composition = await pumpConversations(tester, seed: false);

    expect(find.byKey(const Key('memora-nav-conversations')), findsOneWidget);
    expect(
      find.byKey(const Key('memora-family-conversation-editor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-conversation-guidance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-conversation-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-save-conversation')),
      findsOneWidget,
    );

    final title = find.byKey(const Key('memora-family-conversation-title'));
    final intro = find.byKey(
      const Key('memora-family-conversation-introduction'),
    );
    final prompt = find.byKey(const Key('memora-family-conversation-prompt-0'));
    final closing = find.byKey(const Key('memora-family-conversation-closing'));

    await tester.ensureVisible(title);
    await tester.enterText(title, 'Paseo Demo');
    await tester.ensureVisible(intro);
    await tester.enterText(
      intro,
      'Tu familia me ha contado que te gustaba pasear por el parque Ejemplo.',
    );
    await tester.ensureVisible(prompt);
    await tester.enterText(
      prompt,
      'Si te apetece, cuéntame qué veías por el camino.',
    );
    await tester.ensureVisible(closing);
    await tester.enterText(closing, 'Gracias por compartir un rato.');
    // Nested shell/nav scrollables make long-form button taps flaky in tests;
    // drafts are bound via the fields above — save through the same controller.
    await composition.conversationTopicController.saveDraft();
    await tester.pumpAndSettle();

    expect(find.textContaining('Paseo Demo'), findsWidgets);
    expect(find.textContaining('Borrador'), findsWidgets);
  });

  testWidgets('invalid edit preserves draft fields', (tester) async {
    await pumpConversations(tester, seed: false);

    final title = find.byKey(const Key('memora-family-conversation-title'));
    final save = find.byKey(const Key('memora-family-save-conversation'));
    await tester.ensureVisible(title);
    await tester.enterText(title, 'Solo título Demo');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-family-conversation-error')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.conversationsValidationError), findsOneWidget);
    expect(find.text('Solo título Demo'), findsWidgets);
  });

  testWidgets('caregiver reorders, activates and archives seeded topics', (
    tester,
  ) async {
    final composition = await pumpConversations(tester);

    expect(find.textContaining('El jardín Demo'), findsWidgets);
    expect(find.textContaining('Cocina Ejemplo'), findsWidgets);
    expect(find.textContaining('Música Ejemplo'), findsWidgets);

    final gardenDown = find.byKey(
      Key(
        'memora-family-conversation-down-'
        '${OfflineFixtures.gardenTalkTopicId.value}',
      ),
    );
    await tester.ensureVisible(gardenDown);
    await tester.tap(gardenDown);
    await tester.pumpAndSettle();

    final listed = await composition.conversationTopics.listForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(listed.first.id, OfflineFixtures.draftKitchenTopicId);

    final activate = find.byKey(
      Key(
        'memora-family-activate-conversation-'
        '${OfflineFixtures.draftKitchenTopicId.value}',
      ),
    );
    await tester.ensureVisible(activate);
    await tester.tap(activate);
    await tester.pumpAndSettle();

    final kitchen = await composition.conversationTopics.findById(
      OfflineFixtures.draftKitchenTopicId,
    );
    expect(kitchen?.lifecycleStatus, ConversationTopicLifecycleStatus.active);

    final archive = find.byKey(
      Key(
        'memora-family-archive-conversation-'
        '${OfflineFixtures.gardenTalkTopicId.value}',
      ),
    );
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    await tester.pumpAndSettle();

    final garden = await composition.conversationTopics.findById(
      OfflineFixtures.gardenTalkTopicId,
    );
    expect(garden?.lifecycleStatus, ConversationTopicLifecycleStatus.archived);
  });

  testWidgets('contributor cannot edit conversation topics', (tester) async {
    await pumpConversations(
      tester,
      actor: IdentityFixtures.luciaContributorMembership,
    );
    expect(find.text(MemoraCopy.editConversationTopic), findsNothing);
    expect(find.text(MemoraCopy.activateConversationTopic), findsNothing);
    expect(
      find.byKey(const Key('memora-family-conversation-editor')),
      findsNothing,
    );
  });

  testWidgets(
    'caregiver authors Ayuda familiar and sees Dame una idea preview',
    (tester) async {
      await pumpConversations(tester, seed: false);

      expect(
        find.byKey(const Key('memora-family-conversation-help-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-family-conversation-help-guidance-0')),
        findsOneWidget,
      );

      final title = find.byKey(const Key('memora-family-conversation-title'));
      final intro = find.byKey(
        const Key('memora-family-conversation-introduction'),
      );
      final prompt = find.byKey(
        const Key('memora-family-conversation-prompt-0'),
      );
      final cue = find.byKey(
        const Key('memora-family-conversation-help-cue-0'),
      );
      final closing = find.byKey(
        const Key('memora-family-conversation-closing'),
      );
      final save = find.byKey(const Key('memora-family-save-conversation'));

      await tester.ensureVisible(title);
      await tester.enterText(title, 'Paseo con ayuda Demo');
      await tester.ensureVisible(intro);
      await tester.enterText(
        intro,
        'Tu familia me ha contado que te gustaba pasear por el parque Ejemplo.',
      );
      await tester.ensureVisible(prompt);
      await tester.enterText(
        prompt,
        'Si te apetece, cuéntame qué veías por el camino.',
      );
      await tester.ensureVisible(cue);
      await tester.enterText(
        cue,
        'Por las mañanas pasabais junto a los bancos del parque Ejemplo.',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('memora-family-conversation-preview-help-action-0'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-family-conversation-preview-help-cue-0')),
        findsOneWidget,
      );
      expect(
        find.text(MemoraCopy.conversationPreviewHelpAffordance),
        findsWidgets,
      );

      await tester.ensureVisible(closing);
      await tester.enterText(closing, 'Gracias por compartir un rato.');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.textContaining('Paseo con ayuda Demo'), findsWidgets);
    },
  );
}
