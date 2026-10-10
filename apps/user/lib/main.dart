import 'package:flutter/widgets.dart';

import 'demo_composition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final composition = UserDemoComposition(networkAvailable: false);
  await composition.seedDemoFixtures();
  await composition.load();
  runApp(composition.buildApp());
}
