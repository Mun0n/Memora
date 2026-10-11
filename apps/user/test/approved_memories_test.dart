import 'package:data/data.dart';
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
    UserHomeDestination initialDestination = UserHomeDestination.recuerdos,
    bool networkAvailable = false,
    InMemoryOfflineStore? store,
    bool seed = true,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      store: store,
      networkAvailable: networkAvailable,
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

  testWidgets('phone: approved memory visible; proposed hidden; return home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(tester, size: phoneSize);

      expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
      expect(find.textContaining('Octubre 2026 Demo'), findsOneWidget);
      expect(find.textContaining('Patio Ejemplo'), findsNothing);
      expect(find.byKey(const Key('memora-user-return-home')), findsOneWidget);
      expect(find.text(MemoraCopy.returnHome), findsOneWidget);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tablet: same approved memory contract + return control', (
    tester,
  ) async {
    await pumpUser(tester, size: tabletSize);
    expect(
      find.byKey(
        Key('memora-user-memory-${OfflineFixtures.gardenMemoryId.value}'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-return-home')), findsOneWidget);
    final returnTop = tester.getTopLeft(
      find.byKey(const Key('memora-user-return-home')),
    );
    expect(returnTop.dy, lessThan(200));
  });

  testWidgets('failed media never traps; return home still works', (
    tester,
  ) async {
    final store = InMemoryOfflineStore();
    store.putMemory(
      OfflineFixtures.gardenMemory.copyWith(
        media: OfflineFixtures.gardenMediaFailed,
      ),
    );
    await pumpUser(tester, size: phoneSize, store: store, seed: false);

    expect(
      find.byKey(
        Key('memora-user-media-failed-${OfflineFixtures.gardenMemoryId.value}'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('memora-user-home-tile-recuerdos')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline cached memories remain usable', (tester) async {
    await pumpUser(tester, size: phoneSize, networkAvailable: false);
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
  });

  testWidgets('phone text scale 1.3 keeps memory caption readable', (
    tester,
  ) async {
    await pumpUser(tester, size: phoneSize, textScale: 1.3);
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
