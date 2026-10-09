import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Proves `packages/ui` depends on domain only among project packages.
void main() {
  final packageRoot = Directory.current;
  final pubspec = File('${packageRoot.path}/pubspec.yaml');
  final libDir = Directory('${packageRoot.path}/lib');

  test('pubspec path-depends on domain and not on data', () {
    final text = pubspec.readAsStringSync();
    expect(text, contains('path: ../domain'));
    expect(text, isNot(contains('path: ../data')));
    expect(text.contains('\n  data:'), isFalse);
    expect(text.toLowerCase(), isNot(contains('supabase')));
  });

  test('lib sources import domain and never data or Supabase', () {
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    final forbiddenImport = RegExp(
      r'''import\s+['"]package:(data|supabase)/''',
    );
    var importsDomain = false;

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        forbiddenImport.hasMatch(source),
        isFalse,
        reason: '${file.path} contains a forbidden import',
      );
      if (source.contains("import 'package:domain/") ||
          source.contains('import "package:domain/')) {
        importsDomain = true;
      }
    }

    expect(importsDomain, isTrue);
  });
}
