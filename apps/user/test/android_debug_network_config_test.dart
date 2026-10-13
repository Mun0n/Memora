import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cycle-4 evidence: debug-only cleartext for loopback demo sync.
void main() {
  final androidRoot = Directory('android/app/src');

  test(
    'debug network security permits cleartext only to localhost/127.0.0.1',
    () {
      final config = File(
        '${androidRoot.path}/debug/res/xml/network_security_config.xml',
      );
      expect(config.existsSync(), isTrue, reason: config.path);
      final xml = config.readAsStringSync();
      expect(xml, contains('cleartextTrafficPermitted="true"'));
      expect(xml, contains('localhost'));
      expect(xml, contains('127.0.0.1'));
      expect(xml.toLowerCase(), isNot(contains('0.0.0.0')));
    },
  );

  test('debug manifest wires networkSecurityConfig; profile/main do not', () {
    final debugManifest = File('${androidRoot.path}/debug/AndroidManifest.xml');
    final profileManifest = File(
      '${androidRoot.path}/profile/AndroidManifest.xml',
    );
    final mainManifest = File('${androidRoot.path}/main/AndroidManifest.xml');

    expect(debugManifest.existsSync(), isTrue);
    final debugXml = debugManifest.readAsStringSync();
    expect(
      debugXml,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(debugXml, isNot(contains('usesCleartextTraffic="true"')));

    expect(profileManifest.existsSync(), isTrue);
    final profileXml = profileManifest.readAsStringSync();
    expect(profileXml, isNot(contains('networkSecurityConfig')));
    expect(profileXml, isNot(contains('usesCleartextTraffic')));

    expect(mainManifest.existsSync(), isTrue);
    final mainXml = mainManifest.readAsStringSync();
    expect(mainXml, isNot(contains('networkSecurityConfig')));
    expect(mainXml, isNot(contains('usesCleartextTraffic')));
  });
}
