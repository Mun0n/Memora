import '../pastime_experience.dart';

/// Reviewed Spanish-first themed word set (adult-neutral Demo subjects).
final class WordSearchWordSet {
  const WordSearchWordSet({
    required this.id,
    required this.themeLabelEs,
    required this.words,
  });

  final String id;

  /// Caregiver-facing theme label (fictional Demo).
  final String themeLabelEs;

  /// Uppercase Spanish words including accents / Ñ where applicable.
  final List<String> words;

  /// Word count for [size]: 4 for 8×8, 6 for 10×10 (within 4–8).
  int wordCountFor(WordSearchBoardSize size) {
    return switch (size) {
      WordSearchBoardSize.eightByEight => 4,
      WordSearchBoardSize.tenByTen => 6,
    };
  }

  List<String> wordsForBoard(WordSearchBoardSize size) {
    final count = wordCountFor(size);
    if (words.length < count) {
      throw StateError('word set $id has fewer than $count words');
    }
    return words.take(count).toList(growable: false);
  }
}

/// Closed catalogue of Spanish Demo word sets.
abstract final class WordSearchWordSets {
  static const WordSearchWordSet jardinDemo = WordSearchWordSet(
    id: WordSearchWordSetCatalog.jardinDemo,
    themeLabelEs: 'Jardín Demo',
    words: <String>['TOMATE', 'FLOR', 'HOJA', 'TIERRA', 'RIEGO', 'HUERTO'],
  );

  static const WordSearchWordSet cocinaDemo = WordSearchWordSet(
    id: WordSearchWordSetCatalog.cocinaDemo,
    themeLabelEs: 'Cocina Ejemplo',
    words: <String>['PAN', 'OLLA', 'MESA', 'CAFÉ', 'CUCHARA', 'SARTÉN'],
  );

  static const WordSearchWordSet musicaDemo = WordSearchWordSet(
    id: WordSearchWordSetCatalog.musicaDemo,
    themeLabelEs: 'Música Demo',
    words: <String>['CANCIÓN', 'PIANO', 'NOTA', 'BAILE', 'GUITARRA', 'CORO'],
  );

  static WordSearchWordSet byId(String id) {
    return switch (id) {
      WordSearchWordSetCatalog.jardinDemo => jardinDemo,
      WordSearchWordSetCatalog.cocinaDemo => cocinaDemo,
      WordSearchWordSetCatalog.musicaDemo => musicaDemo,
      _ => throw ArgumentError.value(id, 'id', 'unknown word set'),
    };
  }

  static List<WordSearchWordSet> get all => const <WordSearchWordSet>[
    jardinDemo,
    cocinaDemo,
    musicaDemo,
  ];
}
