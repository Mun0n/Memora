import 'package:flutter/widgets.dart';

import 'demo_composition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connectivity derives from shared local demo transport when configured;
  // default remains isolated offline (no hard-coded networkAvailable: false).
  final composition = FamilyWebDemoComposition();
  await composition.seedDemoFixtures();
  await composition.load();
  runApp(composition.buildApp());
}
