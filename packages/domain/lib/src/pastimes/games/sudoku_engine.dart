import '../content/sudoku_puzzle_packs.dart';
import '../pastime_experience.dart';
import 'seeded_random.dart';

/// Neutral conflict copy (no personal failure language).
const String sudokuConflictMessage =
    'Este número ya está en esta fila, columna o bloque';

/// Immutable snapshot of a Sudoku play session (device-local only).
final class SudokuGameState {
  SudokuGameState({
    required this.boardSize,
    required this.packId,
    required this.seed,
    required this.clues,
    required this.solution,
    required this.values,
    required this.notes,
    required this.selectedIndex,
    required this.completed,
    required this.solutionRevealed,
  });

  final SudokuBoardSize boardSize;
  final String packId;
  final int seed;
  final List<int> clues;
  final List<int> solution;
  final List<int> values;
  final List<Set<int>> notes;
  final int? selectedIndex;
  final bool completed;
  final bool solutionRevealed;

  int get dimension => boardSize.dimension;

  int get cellCount => dimension * dimension;

  bool isClue(int index) => clues[index] != 0;

  SudokuGameState copyWith({
    List<int>? values,
    List<Set<int>>? notes,
    int? selectedIndex,
    bool clearSelection = false,
    bool? completed,
    bool? solutionRevealed,
  }) {
    return SudokuGameState(
      boardSize: boardSize,
      packId: packId,
      seed: seed,
      clues: clues,
      solution: solution,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      selectedIndex: clearSelection
          ? null
          : (selectedIndex ?? this.selectedIndex),
      completed: completed ?? this.completed,
      solutionRevealed: solutionRevealed ?? this.solutionRevealed,
    );
  }

  Map<String, Object?> toRecoveryMap() => <String, Object?>{
    'boardSize': boardSize.wireName,
    'packId': packId,
    'seed': seed,
    'clues': List<int>.from(clues),
    'solution': List<int>.from(solution),
    'values': List<int>.from(values),
    'notes': notes.map((n) => n.toList()..sort()).toList(),
    'selectedIndex': selectedIndex,
    'completed': completed,
    'solutionRevealed': solutionRevealed,
  };

  static SudokuGameState fromRecoveryMap(Map<String, Object?> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? const [];
    return SudokuGameState(
      boardSize: SudokuBoardSize.parse(map['boardSize']! as String),
      packId: map['packId']! as String,
      seed: map['seed']! as int,
      clues: List<int>.from(map['clues']! as List),
      solution: List<int>.from(map['solution']! as List),
      values: List<int>.from(map['values']! as List),
      notes: notesRaw
          .map((raw) => Set<int>.from(raw as List))
          .toList(growable: false),
      selectedIndex: map['selectedIndex'] as int?,
      completed: map['completed'] as bool? ?? false,
      solutionRevealed: map['solutionRevealed'] as bool? ?? false,
    );
  }
}

/// Result of an entry attempt.
final class SudokuEntryResult {
  const SudokuEntryResult({required this.state, this.conflictMessage});

  final SudokuGameState state;
  final String? conflictMessage;
}

/// Deterministic Sudoku rules engine (no scoring, timers or telemetry).
final class SudokuEngine {
  SudokuEngine({SeededRandom Function(int seed)? randomFactory})
    : _randomFactory = randomFactory ?? SeededRandom.new;

  final SeededRandom Function(int seed) _randomFactory;
  final List<SudokuGameState> _undoStack = <SudokuGameState>[];

  SudokuGameState start({
    required SudokuPastimeExperience experience,
    required int seed,
  }) {
    _undoStack.clear();
    final board = SudokuPuzzlePacks.byPackId(experience.puzzlePackId);
    if (board.boardSize != experience.boardSize) {
      throw StateError('pack size mismatch');
    }
    validateReviewedBoard(board);
    final transformed = _transform(board, seed);
    if (_isSolved(transformed.clues, transformed.solution) &&
        transformed.clues.every((c) => c != 0)) {
      throw StateError('board begins already solved');
    }
    final values = List<int>.from(transformed.clues);
    final notes = List<Set<int>>.generate(
      transformed.cellCount,
      (_) => <int>{},
    );
    return SudokuGameState(
      boardSize: board.boardSize,
      packId: board.packId,
      seed: seed,
      clues: transformed.clues,
      solution: transformed.solution,
      values: values,
      notes: notes,
      selectedIndex: null,
      completed: false,
      solutionRevealed: false,
    );
  }

  SudokuGameState selectCell(SudokuGameState state, int index) {
    if (index < 0 || index >= state.cellCount) {
      throw RangeError.index(index, state.values);
    }
    return state.copyWith(selectedIndex: index);
  }

  SudokuEntryResult enterNumber(SudokuGameState state, int number) {
    final index = state.selectedIndex;
    if (index == null) {
      return SudokuEntryResult(state: state);
    }
    if (state.isClue(index)) {
      return SudokuEntryResult(state: state);
    }
    if (number < 1 || number > state.dimension) {
      throw ArgumentError.value(number, 'number', 'out of tray range');
    }
    _pushUndo(state);
    final values = List<int>.from(state.values);
    values[index] = number;
    final notes = _cloneNotes(state.notes);
    notes[index] = <int>{};
    var next = state.copyWith(values: values, notes: notes);
    final conflict = hasConflictAt(next, index);
    next = _withCompletion(next);
    return SudokuEntryResult(
      state: next,
      conflictMessage: conflict ? sudokuConflictMessage : null,
    );
  }

  SudokuGameState toggleNote(SudokuGameState state, int number) {
    final index = state.selectedIndex;
    if (index == null || state.isClue(index)) {
      return state;
    }
    if (number < 1 || number > state.dimension) {
      throw ArgumentError.value(number, 'number', 'out of tray range');
    }
    _pushUndo(state);
    final notes = _cloneNotes(state.notes);
    final cell = Set<int>.from(notes[index]);
    if (cell.contains(number)) {
      cell.remove(number);
    } else {
      cell.add(number);
    }
    notes[index] = cell;
    final values = List<int>.from(state.values)..[index] = 0;
    return state.copyWith(values: values, notes: notes);
  }

  SudokuGameState clearCell(SudokuGameState state) {
    final index = state.selectedIndex;
    if (index == null || state.isClue(index)) {
      return state;
    }
    _pushUndo(state);
    final values = List<int>.from(state.values)..[index] = 0;
    final notes = _cloneNotes(state.notes)..[index] = <int>{};
    return state.copyWith(values: values, notes: notes, completed: false);
  }

  SudokuGameState? undo(SudokuGameState state) {
    if (_undoStack.isEmpty) {
      return null;
    }
    return _undoStack.removeLast();
  }

  /// Requires explicit UI confirmation before calling.
  SudokuGameState revealSolution(SudokuGameState state) {
    _pushUndo(state);
    return state.copyWith(
      values: List<int>.from(state.solution),
      notes: List<Set<int>>.generate(state.cellCount, (_) => <int>{}),
      completed: true,
      solutionRevealed: true,
    );
  }

  SudokuGameState restart(SudokuGameState state) {
    return start(
      experience: SudokuPastimeExperience(
        boardSize: state.boardSize,
        puzzlePackId: state.packId,
      ),
      seed: state.seed,
    );
  }

  bool hasConflictAt(SudokuGameState state, int index) {
    final value = state.values[index];
    if (value == 0) {
      return false;
    }
    final n = state.dimension;
    final row = index ~/ n;
    final col = index % n;
    for (var c = 0; c < n; c++) {
      final i = row * n + c;
      if (i != index && state.values[i] == value) {
        return true;
      }
    }
    for (var r = 0; r < n; r++) {
      final i = r * n + col;
      if (i != index && state.values[i] == value) {
        return true;
      }
    }
    final (boxH, boxW) = boxShape(n);
    final boxRow = row ~/ boxH;
    final boxCol = col ~/ boxW;
    for (var r = boxRow * boxH; r < boxRow * boxH + boxH; r++) {
      for (var c = boxCol * boxW; c < boxCol * boxW + boxW; c++) {
        final i = r * n + c;
        if (i != index && state.values[i] == value) {
          return true;
        }
      }
    }
    return false;
  }

  Set<int> conflictingIndexes(SudokuGameState state) {
    final conflicts = <int>{};
    for (var i = 0; i < state.cellCount; i++) {
      if (state.values[i] != 0 && hasConflictAt(state, i)) {
        conflicts.add(i);
      }
    }
    return conflicts;
  }

  static (int boxH, int boxW) boxShape(int dimension) {
    return switch (dimension) {
      4 => (2, 2),
      6 => (2, 3),
      9 => (3, 3),
      _ => throw ArgumentError.value(dimension, 'dimension'),
    };
  }

  /// Offline catalogue validation: exactly one solution, editable cells exist.
  static void validateReviewedBoard(SudokuReviewedBoard board) {
    final n = board.dimension;
    if (board.clues.length != n * n || board.solution.length != n * n) {
      throw StateError('board length mismatch for ${board.packId}');
    }
    var editable = 0;
    for (var i = 0; i < board.clues.length; i++) {
      final clue = board.clues[i];
      if (clue == 0) {
        editable++;
      } else if (clue != board.solution[i]) {
        throw StateError('clue disagrees with solution at $i');
      }
      if (board.solution[i] < 1 || board.solution[i] > n) {
        throw StateError('solution out of range at $i');
      }
    }
    if (editable == 0) {
      throw StateError('board has no editable cells');
    }
    if (!_gridValid(board.solution, n)) {
      throw StateError('solution grid invalid for ${board.packId}');
    }
    final count = countSolutions(List<int>.from(board.clues), n, limit: 2);
    if (count != 1) {
      throw StateError(
        'board ${board.packId} must have exactly one solution, found $count',
      );
    }
    final solvedFromClues = List<int>.from(board.clues);
    if (!_solveInPlace(solvedFromClues, n) ||
        !_listEquals(solvedFromClues, board.solution)) {
      throw StateError('published solution mismatch for ${board.packId}');
    }
  }

  static int countSolutions(List<int> grid, int n, {int limit = 2}) {
    var found = 0;
    void search() {
      if (found >= limit) {
        return;
      }
      final idx = grid.indexWhere((v) => v == 0);
      if (idx < 0) {
        found++;
        return;
      }
      for (var v = 1; v <= n; v++) {
        if (_canPlace(grid, n, idx, v)) {
          grid[idx] = v;
          search();
          grid[idx] = 0;
          if (found >= limit) {
            return;
          }
        }
      }
    }

    search();
    return found;
  }

  void _pushUndo(SudokuGameState state) {
    _undoStack.add(
      state.copyWith(
        values: List<int>.from(state.values),
        notes: _cloneNotes(state.notes),
      ),
    );
  }

  List<Set<int>> _cloneNotes(List<Set<int>> notes) =>
      notes.map((n) => Set<int>.from(n)).toList();

  SudokuGameState _withCompletion(SudokuGameState state) {
    final done = _isSolved(state.values, state.solution);
    return state.copyWith(completed: done);
  }

  bool _isSolved(List<int> values, List<int> solution) {
    for (var i = 0; i < values.length; i++) {
      if (values[i] != solution[i]) {
        return false;
      }
    }
    return true;
  }

  SudokuReviewedBoard _transform(SudokuReviewedBoard board, int seed) {
    final rng = _randomFactory(seed);
    final n = board.dimension;
    // Digit remapping + optional transpose keep uniqueness.
    final digits = List<int>.generate(n, (i) => i + 1);
    rng.shuffle(digits);
    List<int> mapGrid(List<int> src) {
      return src.map((v) => v == 0 ? 0 : digits[v - 1]).toList(growable: false);
    }

    var clues = mapGrid(board.clues);
    var solution = mapGrid(board.solution);
    if (rng.nextInt(2) == 1) {
      clues = _transpose(clues, n);
      solution = _transpose(solution, n);
    }
    return SudokuReviewedBoard(
      packId: board.packId,
      boardSize: board.boardSize,
      clues: clues,
      solution: solution,
    );
  }

  static List<int> _transpose(List<int> grid, int n) {
    final out = List<int>.filled(n * n, 0);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        out[c * n + r] = grid[r * n + c];
      }
    }
    return out;
  }

  static bool _gridValid(List<int> grid, int n) {
    for (var i = 0; i < grid.length; i++) {
      final v = grid[i];
      if (v < 1 || v > n) {
        return false;
      }
      // Temporarily zero to reuse canPlace uniqueness check.
    }
    final probe = List<int>.filled(n * n, 0);
    for (var i = 0; i < grid.length; i++) {
      if (!_canPlace(probe, n, i, grid[i])) {
        return false;
      }
      probe[i] = grid[i];
    }
    return true;
  }

  static bool _canPlace(List<int> grid, int n, int index, int value) {
    final row = index ~/ n;
    final col = index % n;
    for (var c = 0; c < n; c++) {
      if (grid[row * n + c] == value) {
        return false;
      }
    }
    for (var r = 0; r < n; r++) {
      if (grid[r * n + col] == value) {
        return false;
      }
    }
    final (boxH, boxW) = boxShape(n);
    final boxRow = row ~/ boxH;
    final boxCol = col ~/ boxW;
    for (var r = boxRow * boxH; r < boxRow * boxH + boxH; r++) {
      for (var c = boxCol * boxW; c < boxCol * boxW + boxW; c++) {
        if (grid[r * n + c] == value) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _solveInPlace(List<int> grid, int n) {
    final idx = grid.indexWhere((v) => v == 0);
    if (idx < 0) {
      return true;
    }
    for (var v = 1; v <= n; v++) {
      if (_canPlace(grid, n, idx, v)) {
        grid[idx] = v;
        if (_solveInPlace(grid, n)) {
          return true;
        }
        grid[idx] = 0;
      }
    }
    return false;
  }

  static bool _listEquals(List<int> a, List<int> b) {
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
