import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SudokuPuzzlePacks', () {
    test('every bundled board has unique solution and editable cells', () {
      for (final board in SudokuPuzzlePacks.all) {
        expect(
          () => SudokuEngine.validateReviewedBoard(board),
          returnsNormally,
        );
        final empty = board.clues.where((c) => c == 0).length;
        expect(empty, greaterThan(0));
      }
    });
  });

  group('SudokuEngine', () {
    late SudokuEngine engine;

    setUp(() {
      engine = SudokuEngine();
    });

    test('deterministic start; clues immutable; entry notes undo complete', () {
      final experience = SudokuPastimeExperience(
        boardSize: SudokuBoardSize.fourByFour,
        puzzlePackId: SudokuPuzzlePackCatalog.starter4,
      );
      final a = engine.start(experience: experience, seed: 42);
      final b = engine.start(experience: experience, seed: 42);
      expect(a.clues, b.clues);
      expect(a.solution, b.solution);
      expect(a.values.any((v) => v == 0), isTrue);

      final clueIndex = a.clues.indexWhere((c) => c != 0);
      var state = engine.selectCell(a, clueIndex);
      final blocked = engine.enterNumber(state, 2);
      expect(blocked.state.values[clueIndex], a.clues[clueIndex]);

      final emptyIndex = a.clues.indexWhere((c) => c == 0);
      state = engine.selectCell(a, emptyIndex);
      final entered = engine.enterNumber(state, a.solution[emptyIndex]);
      expect(entered.state.values[emptyIndex], a.solution[emptyIndex]);

      state = engine.selectCell(entered.state, emptyIndex);
      state = engine.toggleNote(state, 1);
      expect(state.notes[emptyIndex].contains(1), isTrue);

      final undone = engine.undo(state);
      expect(undone, isNotNull);
      expect(undone!.values[emptyIndex], a.solution[emptyIndex]);

      // Fill all editable cells to complete.
      state = entered.state;
      for (var i = 0; i < state.cellCount; i++) {
        if (state.clues[i] == 0 && state.values[i] != state.solution[i]) {
          state = engine.selectCell(state, i);
          state = engine.enterNumber(state, state.solution[i]).state;
        }
      }
      expect(state.completed, isTrue);

      final revealed = engine.revealSolution(
        engine.start(experience: experience, seed: 7),
      );
      expect(revealed.completed, isTrue);
      expect(revealed.solutionRevealed, isTrue);
    });

    test('conflicts use neutral message; restart restores clues', () {
      final experience = SudokuPastimeExperience(
        boardSize: SudokuBoardSize.fourByFour,
        puzzlePackId: SudokuPuzzlePackCatalog.starter4,
      );
      var state = engine.start(experience: experience, seed: 1);
      final emptyIndex = state.clues.indexWhere((c) => c == 0);
      // Place a value that duplicates a clue in the same row when possible.
      final row = emptyIndex ~/ state.dimension;
      final clueInRow = List.generate(
        state.dimension,
        (c) => row * state.dimension + c,
      ).firstWhere((i) => state.clues[i] != 0, orElse: () => -1);
      if (clueInRow >= 0) {
        state = engine.selectCell(state, emptyIndex);
        final result = engine.enterNumber(state, state.clues[clueInRow]);
        expect(result.conflictMessage, sudokuConflictMessage);
      }
      final restarted = engine.restart(state);
      expect(restarted.values, restarted.clues);
      expect(restarted.completed, isFalse);
    });
  });
}
