/// Versioned, exhaustive pastime experience definition.
///
/// Transport may use JSON; unknown type/version/fields fail closed into
/// [QuarantinedPastimeExperience] and never map to another playable activity.
/// Caregiver-entered data cannot select executable code.
sealed class PastimeExperience {
  const PastimeExperience();

  /// Wire type name (`guided`, `sudoku`, `wordSearch`, `spiderSolitaire`).
  String get typeWireName;

  /// Schema version for this experience shape.
  int get schemaVersion;

  /// Complete, app-supported configuration eligible for play / activation.
  bool get isCompleteAndSupported;

  /// Stable map for sync codecs (no free-form executable fields).
  Map<String, Object?> toWireMap();

  /// Default for Slice 8 rows without an experience definition.
  static const PastimeExperience guidedDefault = GuidedPastimeExperience();

  /// Parse a wire map. Missing/null → guided. Unknown/invalid → quarantined.
  static PastimeExperience fromWireMap(Object? raw) {
    if (raw == null) {
      return guidedDefault;
    }
    if (raw is! Map) {
      return const QuarantinedPastimeExperience(
        plainLanguageReason:
            'La configuración del pasatiempo no se reconoce y no se puede usar.',
      );
    }
    final map = Map<String, Object?>.from(raw);
    final type = map['type'];
    final version = map['schemaVersion'];
    if (type is! String || version is! int) {
      return const QuarantinedPastimeExperience(
        plainLanguageReason:
            'La configuración del pasatiempo no se reconoce y no se puede usar.',
      );
    }
    try {
      switch (type) {
        case GuidedPastimeExperience.wireType:
          return GuidedPastimeExperience.parse(map);
        case SudokuPastimeExperience.wireType:
          return SudokuPastimeExperience.parse(map);
        case WordSearchPastimeExperience.wireType:
          return WordSearchPastimeExperience.parse(map);
        case SpiderSolitairePastimeExperience.wireType:
          return SpiderSolitairePastimeExperience.parse(map);
        default:
          return const QuarantinedPastimeExperience(
            plainLanguageReason:
                'Este tipo de pasatiempo no está disponible en esta versión.',
          );
      }
    } on FormatException {
      return const QuarantinedPastimeExperience(
        plainLanguageReason:
            'La configuración del pasatiempo no es válida y no se puede usar.',
      );
    } on ArgumentError {
      return const QuarantinedPastimeExperience(
        plainLanguageReason:
            'La configuración del pasatiempo no es válida y no se puede usar.',
      );
    }
  }
}

/// Existing title/instruction pastime with no additional configuration.
final class GuidedPastimeExperience extends PastimeExperience {
  const GuidedPastimeExperience({this.schemaVersion = currentSchemaVersion});

  static const String wireType = 'guided';
  static const int currentSchemaVersion = 1;

  @override
  final int schemaVersion;

  @override
  String get typeWireName => wireType;

  @override
  bool get isCompleteAndSupported => schemaVersion == currentSchemaVersion;

  @override
  Map<String, Object?> toWireMap() => <String, Object?>{
    'type': wireType,
    'schemaVersion': schemaVersion,
  };

  static GuidedPastimeExperience parse(Map<String, Object?> map) {
    final version = map['schemaVersion']! as int;
    if (version != currentSchemaVersion) {
      throw FormatException('unsupported guided schemaVersion: $version');
    }
    // Reject unknown fields beyond the closed contract.
    final keys = map.keys.toSet();
    if (!keys.every((k) => k == 'type' || k == 'schemaVersion')) {
      throw FormatException('unknown guided experience fields');
    }
    return GuidedPastimeExperience(schemaVersion: version);
  }
}

/// Sudoku board size + reviewed puzzle-pack level identifier.
final class SudokuPastimeExperience extends PastimeExperience {
  SudokuPastimeExperience({
    required this.boardSize,
    required this.puzzlePackId,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion', 'unsupported');
    }
    if (!SudokuPuzzlePackCatalog.isAllowed(puzzlePackId, boardSize)) {
      throw ArgumentError.value(
        puzzlePackId,
        'puzzlePackId',
        'not in reviewed allowlist for $boardSize',
      );
    }
  }

  static const String wireType = 'sudoku';
  static const int currentSchemaVersion = 1;

  final SudokuBoardSize boardSize;
  final String puzzlePackId;

  @override
  final int schemaVersion;

  @override
  String get typeWireName => wireType;

  @override
  bool get isCompleteAndSupported =>
      schemaVersion == currentSchemaVersion &&
      SudokuPuzzlePackCatalog.isAllowed(puzzlePackId, boardSize);

  @override
  Map<String, Object?> toWireMap() => <String, Object?>{
    'type': wireType,
    'schemaVersion': schemaVersion,
    'boardSize': boardSize.wireName,
    'puzzlePackId': puzzlePackId,
  };

  static SudokuPastimeExperience parse(Map<String, Object?> map) {
    final version = map['schemaVersion']! as int;
    if (version != currentSchemaVersion) {
      throw FormatException('unsupported sudoku schemaVersion: $version');
    }
    final allowed = {'type', 'schemaVersion', 'boardSize', 'puzzlePackId'};
    if (!map.keys.every(allowed.contains)) {
      throw FormatException('unknown sudoku experience fields');
    }
    final sizeRaw = map['boardSize'];
    final packRaw = map['puzzlePackId'];
    if (sizeRaw is! String || packRaw is! String) {
      throw FormatException('sudoku requires boardSize and puzzlePackId');
    }
    return SudokuPastimeExperience(
      boardSize: SudokuBoardSize.parse(sizeRaw),
      puzzlePackId: packRaw,
      schemaVersion: version,
    );
  }
}

/// Word-search size + reviewed Spanish word-set identifier (no free word list).
final class WordSearchPastimeExperience extends PastimeExperience {
  WordSearchPastimeExperience({
    required this.boardSize,
    required this.wordSetId,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion', 'unsupported');
    }
    if (!WordSearchWordSetCatalog.isAllowed(wordSetId, boardSize)) {
      throw ArgumentError.value(
        wordSetId,
        'wordSetId',
        'not in reviewed allowlist for $boardSize',
      );
    }
  }

  static const String wireType = 'wordSearch';
  static const int currentSchemaVersion = 1;

  final WordSearchBoardSize boardSize;
  final String wordSetId;

  @override
  final int schemaVersion;

  @override
  String get typeWireName => wireType;

  @override
  bool get isCompleteAndSupported =>
      schemaVersion == currentSchemaVersion &&
      WordSearchWordSetCatalog.isAllowed(wordSetId, boardSize);

  @override
  Map<String, Object?> toWireMap() => <String, Object?>{
    'type': wireType,
    'schemaVersion': schemaVersion,
    'boardSize': boardSize.wireName,
    'wordSetId': wordSetId,
  };

  static WordSearchPastimeExperience parse(Map<String, Object?> map) {
    final version = map['schemaVersion']! as int;
    if (version != currentSchemaVersion) {
      throw FormatException('unsupported wordSearch schemaVersion: $version');
    }
    final allowed = {'type', 'schemaVersion', 'boardSize', 'wordSetId'};
    if (!map.keys.every(allowed.contains)) {
      throw FormatException('unknown wordSearch experience fields');
    }
    final sizeRaw = map['boardSize'];
    final setRaw = map['wordSetId'];
    if (sizeRaw is! String || setRaw is! String) {
      throw FormatException('wordSearch requires boardSize and wordSetId');
    }
    return WordSearchPastimeExperience(
      boardSize: WordSearchBoardSize.parse(sizeRaw),
      wordSetId: setRaw,
      schemaVersion: version,
    );
  }
}

/// Spider Solitaire suit-count mode.
final class SpiderSolitairePastimeExperience extends PastimeExperience {
  SpiderSolitairePastimeExperience({
    required this.suitCount,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion', 'unsupported');
    }
  }

  static const String wireType = 'spiderSolitaire';
  static const int currentSchemaVersion = 1;

  final SpiderSuitCount suitCount;

  @override
  final int schemaVersion;

  @override
  String get typeWireName => wireType;

  @override
  bool get isCompleteAndSupported => schemaVersion == currentSchemaVersion;

  @override
  Map<String, Object?> toWireMap() => <String, Object?>{
    'type': wireType,
    'schemaVersion': schemaVersion,
    'suitCount': suitCount.value,
  };

  static SpiderSolitairePastimeExperience parse(Map<String, Object?> map) {
    final version = map['schemaVersion']! as int;
    if (version != currentSchemaVersion) {
      throw FormatException(
        'unsupported spiderSolitaire schemaVersion: $version',
      );
    }
    final allowed = {'type', 'schemaVersion', 'suitCount'};
    if (!map.keys.every(allowed.contains)) {
      throw FormatException('unknown spiderSolitaire experience fields');
    }
    final suitsRaw = map['suitCount'];
    if (suitsRaw is! int) {
      throw FormatException('spiderSolitaire requires suitCount');
    }
    return SpiderSolitairePastimeExperience(
      suitCount: SpiderSuitCount.parse(suitsRaw),
      schemaVersion: version,
    );
  }
}

/// Invalid/unknown remote configuration — never playable.
final class QuarantinedPastimeExperience extends PastimeExperience {
  const QuarantinedPastimeExperience({required this.plainLanguageReason});

  /// Caregiver-facing plain language; never raw JSON or stack traces.
  final String plainLanguageReason;

  @override
  String get typeWireName => 'quarantined';

  @override
  int get schemaVersion => 0;

  @override
  bool get isCompleteAndSupported => false;

  @override
  Map<String, Object?> toWireMap() => <String, Object?>{
    'type': 'quarantined',
    'schemaVersion': 0,
  };
}

/// Sudoku board sizes authorized by Slice 14.
enum SudokuBoardSize {
  fourByFour('4x4', 4),
  sixBySix('6x6', 6),
  nineByNine('9x9', 9);

  const SudokuBoardSize(this.wireName, this.dimension);

  final String wireName;
  final int dimension;

  static SudokuBoardSize parse(String raw) {
    for (final size in SudokuBoardSize.values) {
      if (size.wireName == raw) {
        return size;
      }
    }
    throw FormatException('Unknown SudokuBoardSize: $raw');
  }
}

/// Word-search board sizes authorized by Slice 14.
enum WordSearchBoardSize {
  eightByEight('8x8', 8),
  tenByTen('10x10', 10);

  const WordSearchBoardSize(this.wireName, this.dimension);

  final String wireName;
  final int dimension;

  static WordSearchBoardSize parse(String raw) {
    for (final size in WordSearchBoardSize.values) {
      if (size.wireName == raw) {
        return size;
      }
    }
    throw FormatException('Unknown WordSearchBoardSize: $raw');
  }
}

/// Spider suit-count modes (deck composition only).
enum SpiderSuitCount {
  one(1),
  two(2),
  four(4);

  const SpiderSuitCount(this.value);

  final int value;

  static SpiderSuitCount parse(int raw) {
    for (final mode in SpiderSuitCount.values) {
      if (mode.value == raw) {
        return mode;
      }
    }
    throw FormatException('Unknown SpiderSuitCount: $raw');
  }
}

/// Closed allowlist of reviewed Sudoku puzzle-pack identifiers.
abstract final class SudokuPuzzlePackCatalog {
  static const String starter4 = 'sudoku_starter_4x4_demo';
  static const String starter6 = 'sudoku_starter_6x6_demo';
  static const String starter9 = 'sudoku_starter_9x9_demo';

  static const Set<String> allIds = {starter4, starter6, starter9};

  static bool isAllowed(String id, SudokuBoardSize size) {
    return switch (size) {
      SudokuBoardSize.fourByFour => id == starter4,
      SudokuBoardSize.sixBySix => id == starter6,
      SudokuBoardSize.nineByNine => id == starter9,
    };
  }
}

/// Closed allowlist of reviewed Spanish-first word-set identifiers.
abstract final class WordSearchWordSetCatalog {
  static const String jardinDemo = 'wordset_jardin_demo';
  static const String cocinaDemo = 'wordset_cocina_demo';
  static const String musicaDemo = 'wordset_musica_demo';

  static const Set<String> allIds = {jardinDemo, cocinaDemo, musicaDemo};

  /// Every reviewed set is valid for both board sizes (word count adapts).
  static bool isAllowed(String id, WordSearchBoardSize size) {
    return allIds.contains(id);
  }
}
