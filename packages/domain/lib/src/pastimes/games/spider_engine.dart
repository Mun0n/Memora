import '../pastime_experience.dart';
import 'seeded_random.dart';

/// Playing-card rank (King high down to Ace low for Spider runs).
enum SpiderRank {
  king(13, 'K', 'rey'),
  queen(12, 'Q', 'reina'),
  jack(11, 'J', 'sota'),
  ten(10, '10', 'diez'),
  nine(9, '9', 'nueve'),
  eight(8, '8', 'ocho'),
  seven(7, '7', 'siete'),
  six(6, '6', 'seis'),
  five(5, '5', 'cinco'),
  four(4, '4', 'cuatro'),
  three(3, '3', 'tres'),
  two(2, '2', 'dos'),
  ace(1, 'A', 'as');

  const SpiderRank(this.value, this.symbol, this.labelEs);

  final int value;
  final String symbol;
  final String labelEs;

  static SpiderRank fromValue(int value) {
    for (final r in SpiderRank.values) {
      if (r.value == value) {
        return r;
      }
    }
    throw FormatException('Unknown SpiderRank: $value');
  }
}

/// Suit identity — colour is never the only cue (labelEs always present).
enum SpiderSuit {
  spades('S', 'picas'),
  hearts('H', 'corazones'),
  diamonds('D', 'diamantes'),
  clubs('C', 'tréboles');

  const SpiderSuit(this.symbol, this.labelEs);

  final String symbol;
  final String labelEs;
}

/// One card in the 104-card Spider multiset.
final class SpiderCard {
  const SpiderCard({
    required this.rank,
    required this.suit,
    required this.faceUp,
    required this.instanceId,
  });

  final SpiderRank rank;
  final SpiderSuit suit;
  final bool faceUp;

  /// Distinguishes duplicates in the multiset (0..103).
  final int instanceId;

  SpiderCard copyWith({bool? faceUp}) => SpiderCard(
    rank: rank,
    suit: suit,
    faceUp: faceUp ?? this.faceUp,
    instanceId: instanceId,
  );

  String get semanticLabel {
    final face = faceUp ? 'boca arriba' : 'boca abajo';
    return '${rank.labelEs} de ${suit.labelEs}, $face';
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'rank': rank.value,
    'suit': suit.symbol,
    'faceUp': faceUp,
    'instanceId': instanceId,
  };

  static SpiderCard fromMap(Map<String, Object?> map) {
    final suitSymbol = map['suit']! as String;
    final suit = SpiderSuit.values.firstWhere((s) => s.symbol == suitSymbol);
    return SpiderCard(
      rank: SpiderRank.fromValue(map['rank']! as int),
      suit: suit,
      faceUp: map['faceUp']! as bool,
      instanceId: map['instanceId']! as int,
    );
  }
}

/// Device-local Spider session.
final class SpiderGameState {
  SpiderGameState({
    required this.suitCount,
    required this.seed,
    required this.tableau,
    required this.stock,
    required this.completedRuns,
    required this.selected,
    required this.completed,
    required this.hint,
  });

  final SpiderSuitCount suitCount;
  final int seed;
  final List<List<SpiderCard>> tableau;
  final List<SpiderCard> stock;
  final int completedRuns;
  final SpiderSelection? selected;
  final bool completed;
  final SpiderHint? hint;

  SpiderGameState copyWith({
    List<List<SpiderCard>>? tableau,
    List<SpiderCard>? stock,
    int? completedRuns,
    SpiderSelection? selected,
    bool clearSelection = false,
    bool? completed,
    SpiderHint? hint,
    bool clearHint = false,
  }) {
    return SpiderGameState(
      suitCount: suitCount,
      seed: seed,
      tableau: tableau ?? this.tableau,
      stock: stock ?? this.stock,
      completedRuns: completedRuns ?? this.completedRuns,
      selected: clearSelection ? null : (selected ?? this.selected),
      completed: completed ?? this.completed,
      hint: clearHint ? null : (hint ?? this.hint),
    );
  }

  Map<String, Object?> toRecoveryMap() => <String, Object?>{
    'suitCount': suitCount.value,
    'seed': seed,
    'tableau': tableau
        .map((col) => col.map((c) => c.toMap()).toList())
        .toList(),
    'stock': stock.map((c) => c.toMap()).toList(),
    'completedRuns': completedRuns,
    'selected': selected?.toMap(),
    'completed': completed,
  };

  static SpiderGameState fromRecoveryMap(Map<String, Object?> map) {
    final tableauRaw = map['tableau'] as List<dynamic>;
    final stockRaw = map['stock'] as List<dynamic>;
    final selectedRaw = map['selected'];
    return SpiderGameState(
      suitCount: SpiderSuitCount.parse(map['suitCount']! as int),
      seed: map['seed']! as int,
      tableau: tableauRaw
          .map(
            (col) => (col as List<dynamic>)
                .map(
                  (c) =>
                      SpiderCard.fromMap(Map<String, Object?>.from(c as Map)),
                )
                .toList(),
          )
          .toList(),
      stock: stockRaw
          .map((c) => SpiderCard.fromMap(Map<String, Object?>.from(c as Map)))
          .toList(),
      completedRuns: map['completedRuns']! as int,
      selected: selectedRaw == null
          ? null
          : SpiderSelection.fromMap(
              Map<String, Object?>.from(selectedRaw as Map),
            ),
      completed: map['completed'] as bool? ?? false,
      hint: null,
    );
  }
}

final class SpiderSelection {
  const SpiderSelection({required this.column, required this.fromIndex});

  final int column;
  final int fromIndex;

  Map<String, Object?> toMap() => <String, Object?>{
    'column': column,
    'fromIndex': fromIndex,
  };

  static SpiderSelection fromMap(Map<String, Object?> map) => SpiderSelection(
    column: map['column']! as int,
    fromIndex: map['fromIndex']! as int,
  );
}

final class SpiderHint {
  const SpiderHint({
    required this.fromColumn,
    required this.fromIndex,
    required this.toColumn,
  });

  final int fromColumn;
  final int fromIndex;
  final int toColumn;
}

final class SpiderActionResult {
  const SpiderActionResult({required this.state, this.neutralMessage});

  final SpiderGameState state;
  final String? neutralMessage;
}

/// Standard Spider Solitaire rules (leisure only; no scores or streaks).
final class SpiderEngine {
  SpiderEngine({SeededRandom Function(int seed)? randomFactory})
    : _randomFactory = randomFactory ?? SeededRandom.new;

  final SeededRandom Function(int seed) _randomFactory;
  final List<SpiderGameState> _undoStack = <SpiderGameState>[];

  static const int columnCount = 10;
  static const int deckSize = 104;
  static const int initialDealCount = 54;
  static const int stockDealCount = 5;
  static const int cardsPerStockDeal = 10;
  static const int runsToComplete = 8;

  SpiderGameState start({
    required SpiderSolitairePastimeExperience experience,
    required int seed,
  }) {
    _undoStack.clear();
    final deck = buildDeck(experience.suitCount);
    final rng = _randomFactory(seed);
    rng.shuffle(deck);
    if (deck.length != deckSize) {
      throw StateError('deck must contain $deckSize cards');
    }

    final tableau = List.generate(columnCount, (_) => <SpiderCard>[]);
    var index = 0;
    // Standard deal: 4 columns of 6, then 6 columns of 5 (54 cards).
    for (var col = 0; col < columnCount; col++) {
      final count = col < 4 ? 6 : 5;
      for (var i = 0; i < count; i++) {
        final faceUp = i == count - 1;
        tableau[col].add(deck[index].copyWith(faceUp: faceUp));
        index++;
      }
    }
    if (index != initialDealCount) {
      throw StateError('initial deal must be $initialDealCount cards');
    }
    final stock = deck
        .sublist(index)
        .map((c) => c.copyWith(faceUp: false))
        .toList();
    if (stock.length != stockDealCount * cardsPerStockDeal) {
      throw StateError('stock must allow $stockDealCount deals');
    }

    return SpiderGameState(
      suitCount: experience.suitCount,
      seed: seed,
      tableau: tableau,
      stock: stock,
      completedRuns: 0,
      selected: null,
      completed: false,
      hint: null,
    );
  }

  /// Builds the exact 104-card multiset for the suit mode.
  static List<SpiderCard> buildDeck(SpiderSuitCount suitCount) {
    final suits = switch (suitCount) {
      SpiderSuitCount.one => <SpiderSuit>[
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
        SpiderSuit.spades,
      ],
      SpiderSuitCount.two => <SpiderSuit>[
        for (var i = 0; i < 4; i++) SpiderSuit.spades,
        for (var i = 0; i < 4; i++) SpiderSuit.hearts,
      ],
      SpiderSuitCount.four => <SpiderSuit>[
        for (var i = 0; i < 2; i++) SpiderSuit.spades,
        for (var i = 0; i < 2; i++) SpiderSuit.hearts,
        for (var i = 0; i < 2; i++) SpiderSuit.diamonds,
        for (var i = 0; i < 2; i++) SpiderSuit.clubs,
      ],
    };
    // 8 suits-slots × 13 ranks = 104.
    final deck = <SpiderCard>[];
    var instance = 0;
    for (final suit in suits) {
      for (final rank in SpiderRank.values) {
        deck.add(
          SpiderCard(
            rank: rank,
            suit: suit,
            faceUp: false,
            instanceId: instance++,
          ),
        );
      }
    }
    return deck;
  }

  SpiderActionResult tapCard(SpiderGameState state, int column, int index) {
    _assertColumn(column);
    final col = state.tableau[column];
    if (index < 0 || index >= col.length) {
      throw RangeError.index(index, col);
    }
    final card = col[index];
    if (!card.faceUp) {
      return SpiderActionResult(state: state.copyWith(clearHint: true));
    }
    if (!_isMovableRun(col, index)) {
      return SpiderActionResult(
        state: state.copyWith(clearSelection: true, clearHint: true),
        neutralMessage:
            'Solo se puede mover una secuencia descendente del mismo palo.',
      );
    }
    return SpiderActionResult(
      state: state.copyWith(
        selected: SpiderSelection(column: column, fromIndex: index),
        clearHint: true,
      ),
    );
  }

  SpiderActionResult tapColumnDestination(SpiderGameState state, int toColumn) {
    _assertColumn(toColumn);
    final selected = state.selected;
    if (selected == null) {
      return SpiderActionResult(state: state);
    }
    return moveRun(state, selected.column, selected.fromIndex, toColumn);
  }

  SpiderActionResult moveRun(
    SpiderGameState state,
    int fromColumn,
    int fromIndex,
    int toColumn,
  ) {
    _assertColumn(fromColumn);
    _assertColumn(toColumn);
    if (fromColumn == toColumn) {
      return SpiderActionResult(
        state: state.copyWith(clearSelection: true, clearHint: true),
      );
    }
    final from = state.tableau[fromColumn];
    if (!_isMovableRun(from, fromIndex)) {
      return SpiderActionResult(
        state: state.copyWith(clearSelection: true, clearHint: true),
        neutralMessage:
            'Solo se puede mover una secuencia descendente del mismo palo.',
      );
    }
    final moving = from.sublist(fromIndex);
    final to = state.tableau[toColumn];
    if (to.isNotEmpty) {
      final dest = to.last;
      if (!dest.faceUp || dest.rank.value != moving.first.rank.value + 1) {
        return SpiderActionResult(
          state: state.copyWith(clearSelection: true, clearHint: true),
          neutralMessage:
              'La carta debe colocarse sobre la siguiente superior en valor.',
        );
      }
    }

    _pushUndo(state);
    final tableau = _cloneTableau(state.tableau);
    tableau[fromColumn] = List<SpiderCard>.from(from.sublist(0, fromIndex));
    if (tableau[fromColumn].isNotEmpty && !tableau[fromColumn].last.faceUp) {
      final last = tableau[fromColumn].removeLast();
      tableau[fromColumn].add(last.copyWith(faceUp: true));
    }
    tableau[toColumn] = List<SpiderCard>.from(to)..addAll(moving);

    var next = state.copyWith(
      tableau: tableau,
      clearSelection: true,
      clearHint: true,
    );
    next = _removeCompletedRuns(next);
    return SpiderActionResult(state: next);
  }

  SpiderActionResult dealStock(SpiderGameState state) {
    if (state.stock.isEmpty) {
      return SpiderActionResult(
        state: state,
        neutralMessage: 'No quedan cartas en el mazo.',
      );
    }
    if (state.tableau.any((col) => col.isEmpty)) {
      return SpiderActionResult(
        state: state.copyWith(clearSelection: true, clearHint: true),
        neutralMessage: 'No se puede repartir mientras haya una columna vacía.',
      );
    }
    if (state.stock.length < cardsPerStockDeal) {
      throw StateError('stock corrupted');
    }
    _pushUndo(state);
    final tableau = _cloneTableau(state.tableau);
    final stock = List<SpiderCard>.from(state.stock);
    for (var col = 0; col < columnCount; col++) {
      final card = stock.removeAt(0).copyWith(faceUp: true);
      tableau[col] = List<SpiderCard>.from(tableau[col])..add(card);
    }
    var next = state.copyWith(
      tableau: tableau,
      stock: stock,
      clearSelection: true,
      clearHint: true,
    );
    next = _removeCompletedRuns(next);
    return SpiderActionResult(state: next);
  }

  /// Highlights one legal move without mutating the board.
  SpiderGameState showHint(SpiderGameState state) {
    final hint = findHint(state);
    return state.copyWith(hint: hint, clearHint: hint == null);
  }

  SpiderHint? findHint(SpiderGameState state) {
    for (var from = 0; from < columnCount; from++) {
      final col = state.tableau[from];
      for (var i = 0; i < col.length; i++) {
        if (!col[i].faceUp || !_isMovableRun(col, i)) {
          continue;
        }
        for (var to = 0; to < columnCount; to++) {
          if (to == from) {
            continue;
          }
          final destCol = state.tableau[to];
          final moving = col[i];
          if (destCol.isEmpty) {
            return SpiderHint(fromColumn: from, fromIndex: i, toColumn: to);
          }
          final dest = destCol.last;
          if (dest.faceUp && dest.rank.value == moving.rank.value + 1) {
            return SpiderHint(fromColumn: from, fromIndex: i, toColumn: to);
          }
        }
      }
    }
    return null;
  }

  SpiderGameState? undo(SpiderGameState state) {
    if (_undoStack.isEmpty) {
      return null;
    }
    return _undoStack.removeLast();
  }

  SpiderGameState restart(SpiderGameState state) {
    return start(
      experience: SpiderSolitairePastimeExperience(suitCount: state.suitCount),
      seed: state.seed,
    );
  }

  bool _isMovableRun(List<SpiderCard> column, int fromIndex) {
    if (fromIndex < 0 || fromIndex >= column.length) {
      return false;
    }
    if (!column[fromIndex].faceUp) {
      return false;
    }
    for (var i = fromIndex; i < column.length - 1; i++) {
      final a = column[i];
      final b = column[i + 1];
      if (!a.faceUp || !b.faceUp) {
        return false;
      }
      if (a.suit != b.suit) {
        return false;
      }
      if (a.rank.value != b.rank.value + 1) {
        return false;
      }
    }
    return true;
  }

  SpiderGameState _removeCompletedRuns(SpiderGameState state) {
    var tableau = _cloneTableau(state.tableau);
    var runs = state.completedRuns;
    var changed = true;
    while (changed) {
      changed = false;
      for (var col = 0; col < columnCount; col++) {
        final column = tableau[col];
        if (column.length < 13) {
          continue;
        }
        final start = column.length - 13;
        if (!_isMovableRun(column, start)) {
          continue;
        }
        if (column[start].rank != SpiderRank.king ||
            column.last.rank != SpiderRank.ace) {
          continue;
        }
        // Expose card beneath if needed.
        final remaining = List<SpiderCard>.from(column.sublist(0, start));
        if (remaining.isNotEmpty && !remaining.last.faceUp) {
          final last = remaining.removeLast();
          remaining.add(last.copyWith(faceUp: true));
        }
        tableau[col] = remaining;
        runs++;
        changed = true;
      }
    }
    return state.copyWith(
      tableau: tableau,
      completedRuns: runs,
      completed: runs >= runsToComplete,
      clearSelection: true,
      clearHint: true,
    );
  }

  void _pushUndo(SpiderGameState state) {
    _undoStack.add(
      state.copyWith(
        tableau: _cloneTableau(state.tableau),
        stock: List<SpiderCard>.from(state.stock),
        clearHint: true,
      ),
    );
  }

  List<List<SpiderCard>> _cloneTableau(List<List<SpiderCard>> tableau) =>
      tableau.map((col) => List<SpiderCard>.from(col)).toList();

  void _assertColumn(int column) {
    if (column < 0 || column >= columnCount) {
      throw RangeError.range(column, 0, columnCount - 1, 'column');
    }
  }
}
