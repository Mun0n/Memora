import '../content/word_search_word_sets.dart';
import '../pastime_experience.dart';
import 'seeded_random.dart';

/// Inclusive cell coordinate on a word-search board.
final class WordSearchCell {
  const WordSearchCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is WordSearchCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  Map<String, Object?> toMap() => <String, Object?>{'row': row, 'col': col};

  static WordSearchCell fromMap(Map<String, Object?> map) =>
      WordSearchCell(map['row']! as int, map['col']! as int);
}

/// Placement of one word (straight line, deterministic).
final class WordSearchPlacement {
  const WordSearchPlacement({required this.word, required this.cells});

  final String word;
  final List<WordSearchCell> cells;
}

/// Device-local word-search session state.
final class WordSearchGameState {
  WordSearchGameState({
    required this.boardSize,
    required this.wordSetId,
    required this.seed,
    required this.grid,
    required this.words,
    required this.placements,
    required this.foundWords,
    required this.anchor,
    required this.completed,
  });

  final WordSearchBoardSize boardSize;
  final String wordSetId;
  final int seed;
  final List<List<String>> grid;
  final List<String> words;
  final List<WordSearchPlacement> placements;
  final Set<String> foundWords;
  final WordSearchCell? anchor;
  final bool completed;

  int get dimension => boardSize.dimension;

  WordSearchGameState copyWith({
    Set<String>? foundWords,
    WordSearchCell? anchor,
    bool clearAnchor = false,
    bool? completed,
  }) {
    return WordSearchGameState(
      boardSize: boardSize,
      wordSetId: wordSetId,
      seed: seed,
      grid: grid,
      words: words,
      placements: placements,
      foundWords: foundWords ?? this.foundWords,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object?> toRecoveryMap() => <String, Object?>{
    'boardSize': boardSize.wireName,
    'wordSetId': wordSetId,
    'seed': seed,
    'grid': grid,
    'words': words,
    'placements': placements
        .map(
          (p) => <String, Object?>{
            'word': p.word,
            'cells': p.cells.map((c) => c.toMap()).toList(),
          },
        )
        .toList(),
    'foundWords': foundWords.toList()..sort(),
    'anchor': anchor?.toMap(),
    'completed': completed,
  };

  static WordSearchGameState fromRecoveryMap(Map<String, Object?> map) {
    final gridRaw = map['grid'] as List<dynamic>;
    final placementsRaw = map['placements'] as List<dynamic>;
    final foundRaw = map['foundWords'] as List<dynamic>? ?? const [];
    final anchorRaw = map['anchor'];
    return WordSearchGameState(
      boardSize: WordSearchBoardSize.parse(map['boardSize']! as String),
      wordSetId: map['wordSetId']! as String,
      seed: map['seed']! as int,
      grid: gridRaw
          .map((row) => List<String>.from(row as List))
          .toList(growable: false),
      words: List<String>.from(map['words']! as List),
      placements: placementsRaw
          .map((raw) {
            final m = Map<String, Object?>.from(raw as Map);
            final cells = (m['cells'] as List<dynamic>)
                .map(
                  (c) => WordSearchCell.fromMap(
                    Map<String, Object?>.from(c as Map),
                  ),
                )
                .toList(growable: false);
            return WordSearchPlacement(
              word: m['word']! as String,
              cells: cells,
            );
          })
          .toList(growable: false),
      foundWords: foundRaw.map((e) => e as String).toSet(),
      anchor: anchorRaw == null
          ? null
          : WordSearchCell.fromMap(Map<String, Object?>.from(anchorRaw as Map)),
      completed: map['completed'] as bool? ?? false,
    );
  }
}

/// Result of an endpoint tap selection.
final class WordSearchSelectResult {
  const WordSearchSelectResult({
    required this.state,
    this.foundWord,
    this.neutralGuidance,
  });

  final WordSearchGameState state;
  final String? foundWord;

  /// Neutral guidance when the range is not a placed word (no error count).
  final String? neutralGuidance;
}

/// Deterministic Spanish word-search generator and tap-endpoint rules.
final class WordSearchEngine {
  WordSearchEngine({SeededRandom Function(int seed)? randomFactory})
    : _randomFactory = randomFactory ?? SeededRandom.new;

  final SeededRandom Function(int seed) _randomFactory;

  /// Matching is case-sensitive on the normalized uppercase catalogue form.
  /// Accents and Ñ are significant and compared exactly as stored.
  static const String matchingRuleNote =
      'Exact uppercase match including accents and Ñ; straight lines only.';

  WordSearchGameState start({
    required WordSearchPastimeExperience experience,
    required int seed,
  }) {
    final set = WordSearchWordSets.byId(experience.wordSetId);
    final words = set.wordsForBoard(experience.boardSize);
    final generated = generateBoard(
      dimension: experience.boardSize.dimension,
      words: words,
      seed: seed,
    );
    return WordSearchGameState(
      boardSize: experience.boardSize,
      wordSetId: experience.wordSetId,
      seed: seed,
      grid: generated.grid,
      words: words,
      placements: generated.placements,
      foundWords: <String>{},
      anchor: null,
      completed: false,
    );
  }

  WordSearchGameState tapCell(WordSearchGameState state, WordSearchCell cell) {
    _assertInBounds(state, cell);
    if (state.anchor == null) {
      return state.copyWith(anchor: cell);
    }
    if (state.anchor == cell) {
      return state.copyWith(clearAnchor: true);
    }
    return selectEndpoints(state, state.anchor!, cell).state;
  }

  WordSearchSelectResult selectEndpoints(
    WordSearchGameState state,
    WordSearchCell start,
    WordSearchCell end,
  ) {
    _assertInBounds(state, start);
    _assertInBounds(state, end);
    final path = straightPath(start, end);
    if (path == null) {
      return WordSearchSelectResult(
        state: state.copyWith(clearAnchor: true),
        neutralGuidance: 'Elige dos letras en línea recta.',
      );
    }
    final letters = path.map((c) => state.grid[c.row][c.col]).join();
    final reverse = letters.split('').reversed.join();
    String? matched;
    for (final word in state.words) {
      if (word == letters || word == reverse) {
        matched = word;
        break;
      }
    }
    if (matched == null) {
      return WordSearchSelectResult(
        state: state.copyWith(clearAnchor: true),
        neutralGuidance: 'Esa selección no es una palabra de la lista.',
      );
    }
    if (state.foundWords.contains(matched)) {
      return WordSearchSelectResult(state: state.copyWith(clearAnchor: true));
    }
    // Confirm the path matches the intended placement cells (order or reverse).
    final placement = state.placements.firstWhere((p) => p.word == matched);
    final forward = _sameCells(path, placement.cells);
    final backward = _sameCells(path.reversed.toList(), placement.cells);
    if (!forward && !backward) {
      return WordSearchSelectResult(
        state: state.copyWith(clearAnchor: true),
        neutralGuidance: 'Esa selección no es una palabra de la lista.',
      );
    }
    final found = Set<String>.from(state.foundWords)..add(matched);
    final completed = found.length == state.words.length;
    return WordSearchSelectResult(
      state: state.copyWith(
        foundWords: found,
        clearAnchor: true,
        completed: completed,
      ),
      foundWord: matched,
    );
  }

  WordSearchGameState clearSelection(WordSearchGameState state) =>
      state.copyWith(clearAnchor: true);

  WordSearchGameState restart(WordSearchGameState state) {
    return start(
      experience: WordSearchPastimeExperience(
        boardSize: state.boardSize,
        wordSetId: state.wordSetId,
      ),
      seed: state.seed,
    );
  }

  /// Places every word exactly once; fills remaining cells deterministically.
  ({List<List<String>> grid, List<WordSearchPlacement> placements})
  generateBoard({
    required int dimension,
    required List<String> words,
    required int seed,
  }) {
    if (words.isEmpty || words.length < 4 || words.length > 8) {
      throw ArgumentError.value(words.length, 'words', 'must be 4–8');
    }
    final rng = _randomFactory(seed);
    final directions = <(int, int)>[
      (0, 1),
      (1, 0),
      (1, 1),
      (1, -1),
      (0, -1),
      (-1, 0),
      (-1, 1),
      (-1, -1),
    ];
    final grid = List.generate(
      dimension,
      (_) => List.filled(dimension, '', growable: false),
      growable: false,
    );
    final placements = <WordSearchPlacement>[];
    final ordered = List<String>.from(words);
    rng.shuffle(ordered);

    for (final word in ordered) {
      final placed = _placeWord(
        grid: grid,
        word: word,
        dimension: dimension,
        directions: directions,
        rng: rng,
      );
      if (placed == null) {
        throw StateError(
          'failed to place word $word on ${dimension}x$dimension',
        );
      }
      placements.add(placed);
    }

    const alphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚÜ';
    for (var r = 0; r < dimension; r++) {
      for (var c = 0; c < dimension; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = alphabet[rng.nextInt(alphabet.length)];
        }
      }
    }

    // Validate every requested word appears exactly once as placed.
    if (placements.length != words.length) {
      throw StateError('placement count mismatch');
    }
    final placedWords = placements.map((p) => p.word).toSet();
    if (placedWords.length != words.length ||
        !words.every(placedWords.contains)) {
      throw StateError('not every word was placed exactly once');
    }
    for (final p in placements) {
      final built = p.cells.map((c) => grid[c.row][c.col]).join();
      if (built != p.word) {
        throw StateError('grid does not match placement for ${p.word}');
      }
    }

    return (grid: grid, placements: placements);
  }

  /// Straight inclusive path, or null if not a straight line / single cell.
  static List<WordSearchCell>? straightPath(
    WordSearchCell start,
    WordSearchCell end,
  ) {
    final dr = end.row - start.row;
    final dc = end.col - start.col;
    if (dr == 0 && dc == 0) {
      return null;
    }
    final steps = dr.abs() > dc.abs() ? dr.abs() : dc.abs();
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) {
      return null;
    }
    if (steps == 0) {
      return null;
    }
    final stepR = dr == 0 ? 0 : dr ~/ dr.abs();
    final stepC = dc == 0 ? 0 : dc ~/ dc.abs();
    if (dr != 0 && dr.abs() != steps) {
      return null;
    }
    if (dc != 0 && dc.abs() != steps) {
      return null;
    }
    final path = <WordSearchCell>[];
    for (var i = 0; i <= steps; i++) {
      path.add(WordSearchCell(start.row + stepR * i, start.col + stepC * i));
    }
    return path;
  }

  WordSearchPlacement? _placeWord({
    required List<List<String>> grid,
    required String word,
    required int dimension,
    required List<(int, int)> directions,
    required SeededRandom rng,
  }) {
    final dirs = List<(int, int)>.from(directions);
    rng.shuffle(dirs);
    final starts = <WordSearchCell>[
      for (var r = 0; r < dimension; r++)
        for (var c = 0; c < dimension; c++) WordSearchCell(r, c),
    ];
    rng.shuffle(starts);
    for (final dir in dirs) {
      for (final start in starts) {
        final cells = <WordSearchCell>[];
        var ok = true;
        for (var i = 0; i < word.length; i++) {
          final r = start.row + dir.$1 * i;
          final c = start.col + dir.$2 * i;
          if (r < 0 || r >= dimension || c < 0 || c >= dimension) {
            ok = false;
            break;
          }
          final existing = grid[r][c];
          if (existing.isNotEmpty && existing != word[i]) {
            ok = false;
            break;
          }
          cells.add(WordSearchCell(r, c));
        }
        if (!ok) {
          continue;
        }
        for (var i = 0; i < word.length; i++) {
          grid[cells[i].row][cells[i].col] = word[i];
        }
        return WordSearchPlacement(word: word, cells: cells);
      }
    }
    return null;
  }

  void _assertInBounds(WordSearchGameState state, WordSearchCell cell) {
    if (cell.row < 0 ||
        cell.col < 0 ||
        cell.row >= state.dimension ||
        cell.col >= state.dimension) {
      throw RangeError('cell out of bounds: (${cell.row},${cell.col})');
    }
  }

  bool _sameCells(List<WordSearchCell> a, List<WordSearchCell> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
