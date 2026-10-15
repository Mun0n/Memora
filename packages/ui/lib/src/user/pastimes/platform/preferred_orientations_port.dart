import 'package:flutter/services.dart';

/// Injectable boundary for preferred device orientations.
///
/// Spider play locks landscape on supported mobile platforms; every exit path
/// must restore the app defaults through this port (tests inject a recorder).
abstract class PreferredOrientationsPort {
  Future<void> lockLandscape();

  Future<void> restoreAppDefaults();
}

/// No-op default — safe for widget tests and desktop shells.
final class NoopPreferredOrientationsPort implements PreferredOrientationsPort {
  const NoopPreferredOrientationsPort();

  @override
  Future<void> lockLandscape() async {}

  @override
  Future<void> restoreAppDefaults() async {}
}

/// Production/demo boundary backed by [SystemChrome].
final class SystemPreferredOrientationsPort
    implements PreferredOrientationsPort {
  const SystemPreferredOrientationsPort();

  static const List<DeviceOrientation> landscapeOnly = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static const List<DeviceOrientation> appDefaults = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  Future<void> lockLandscape() =>
      SystemChrome.setPreferredOrientations(landscapeOnly);

  @override
  Future<void> restoreAppDefaults() =>
      SystemChrome.setPreferredOrientations(appDefaults);
}

/// Test double that records lock/restore calls without touching channels.
final class RecordingPreferredOrientationsPort
    implements PreferredOrientationsPort {
  final List<String> calls = <String>[];

  @override
  Future<void> lockLandscape() async {
    calls.add('lockLandscape');
  }

  @override
  Future<void> restoreAppDefaults() async {
    calls.add('restoreAppDefaults');
  }
}
