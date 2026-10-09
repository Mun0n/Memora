import 'dart:io';

import 'package:test/test.dart';

/// Proves `packages/data` depends on `domain` only among project packages.
void main() {
  final packageRoot = Directory.current;
  final pubspecFile = File('${packageRoot.path}/pubspec.yaml');
  final libDir = Directory('${packageRoot.path}/lib');

  test('pubspec depends on path domain only among project packages', () {
    final text = pubspecFile.readAsStringSync();
    expect(text, contains('domain:'));
    expect(text, contains('path: ../domain'));
    expect(text, isNot(contains('packages/ui')));
    expect(text, isNot(contains('\n  ui:')));
    expect(text, isNot(contains('flutter:')));
    expect(text.toLowerCase(), isNot(contains('supabase')));

    final pathDeps = RegExp(r'path:\s*(\S+)').allMatches(text).map((m) {
      return m.group(1)!;
    }).toList();
    expect(pathDeps, <String>['../domain']);
  });

  test('lib sources do not import Flutter, Supabase or ui', () {
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    final forbidden = RegExp(r'''package:(flutter|supabase|ui)/|dart:ui\b''');

    var importsDomain = false;
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        forbidden.hasMatch(source),
        isFalse,
        reason: '${file.path} contains a forbidden import',
      );
      if (source.contains('package:domain/')) {
        importsDomain = true;
      }
    }
    expect(importsDomain, isTrue, reason: 'data lib must import domain');
  });
}
