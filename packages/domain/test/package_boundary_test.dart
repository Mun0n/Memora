import 'dart:io';

import 'package:test/test.dart';

/// Proves `packages/domain` has no project-specific or Flutter/Supabase deps.
void main() {
  final packageRoot = Directory.current;
  final pubspec = File('${packageRoot.path}/pubspec.yaml');
  final libDir = Directory('${packageRoot.path}/lib');

  test('pubspec has no Flutter, Supabase or path dependencies', () {
    final text = pubspec.readAsStringSync();
    expect(text, isNot(contains('flutter:')));
    expect(text.toLowerCase(), isNot(contains('supabase')));
    expect(text, isNot(contains('path:')));
    expect(text, isNot(contains('packages/')));
  });

  test('lib sources do not import Flutter, Supabase or sibling packages', () {
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final forbidden = RegExp(
      r'''package:(flutter|supabase|data|ui)/|dart:ui\b''',
    );

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        forbidden.hasMatch(source),
        isFalse,
        reason: '${file.path} contains a forbidden import',
      );
    }
  });
}
