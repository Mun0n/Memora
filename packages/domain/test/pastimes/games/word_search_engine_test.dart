import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WordSearchWordSets', () {
    test('Spanish accents and Ñ appear in reviewed sets', () {
      final allWords = WordSearchWordSets.all.expand((s) => s.words).join();
      expect(
        allWords.contains('Ñ') ||
            allWords.contains('Á') ||
            allWords.contains('É'),
        isTrue,
      );
      expect(WordSearchWordSets.cocinaDemo.words, contains('CAFÉ'));
      expect(WordSearchWordSets.cocinaDemo.words, contains('SARTÉN'));
      expect(WordSearchWordSets.musicaDemo.words, contains('CANCIÓN'));
    });
  });

  group('WordSearchEngine', () {
    late WordSearchEngine engine;

    setUp(() {
      engine = WordSearchEngine();
    });

    test('deterministic generation places every word exactly once', () {
      final experience = WordSearchPastimeExperience(
        boardSize: WordSearchBoardSize.eightByEight,
        wordSetId: WordSearchWordSetCatalog.jardinDemo,
      );
      final a = engine.start(experience: experience, seed: 99);
      final b = engine.start(experience: experience, seed: 99);
      expect(a.grid, b.grid);
      expect(a.words.length, inInclusiveRange(4, 8));
      expect(a.placements.length, a.words.length);
      for (final placement in a.placements) {
        final built = placement.cells.map((c) => a.grid[c.row][c.col]).join();
        expect(built, placement.word);
      }
    });

    test('tap endpoints find words; invalid selection is neutral', () {
      final experience = WordSearchPastimeExperience(
        boardSize: WordSearchBoardSize.eightByEight,
        wordSetId: WordSearchWordSetCatalog.jardinDemo,
      );
      var state = engine.start(experience: experience, seed: 3);
      final first = state.placements.first;
      var result = engine.selectEndpoints(
        state,
        first.cells.first,
        first.cells.last,
      );
      expect(result.foundWord, first.word);
      expect(result.state.foundWords, contains(first.word));

      result = engine.selectEndpoints(
        result.state,
        const WordSearchCell(0, 0),
        const WordSearchCell(0, 1),
      );
      expect(result.foundWord, isNull);
      expect(result.neutralGuidance, isNotNull);
      expect(result.neutralGuidance!.toLowerCase(), isNot(contains('fallo')));

      // Complete remaining words.
      state = result.state;
      for (final placement in state.placements) {
        if (state.foundWords.contains(placement.word)) {
          continue;
        }
        state = engine
            .selectEndpoints(state, placement.cells.first, placement.cells.last)
            .state;
      }
      expect(state.completed, isTrue);

      final restarted = engine.restart(state);
      expect(restarted.foundWords, isEmpty);
      expect(restarted.completed, isFalse);
    });

    test('non-straight selection is rejected', () {
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(0, 0),
          const WordSearchCell(1, 2),
        ),
        isNull,
      );
    });

    test('straightPath covers eight directions including reverse', () {
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(2, 2),
          const WordSearchCell(2, 5),
        )?.map((c) => '${c.row},${c.col}'),
        ['2,2', '2,3', '2,4', '2,5'],
      );
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(2, 5),
          const WordSearchCell(2, 2),
        )?.map((c) => '${c.row},${c.col}'),
        ['2,5', '2,4', '2,3', '2,2'],
      );
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(0, 1),
          const WordSearchCell(3, 1),
        )?.length,
        4,
      );
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(0, 0),
          const WordSearchCell(2, 2),
        )?.map((c) => '${c.row},${c.col}'),
        ['0,0', '1,1', '2,2'],
      );
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(2, 2),
          const WordSearchCell(0, 0),
        )?.map((c) => '${c.row},${c.col}'),
        ['2,2', '1,1', '0,0'],
      );
      expect(
        WordSearchEngine.straightPath(
          const WordSearchCell(0, 3),
          const WordSearchCell(3, 0),
        )?.length,
        4,
      );
    });

    test('already-found word selection clears without mutating found set', () {
      final experience = WordSearchPastimeExperience(
        boardSize: WordSearchBoardSize.eightByEight,
        wordSetId: WordSearchWordSetCatalog.jardinDemo,
      );
      var state = engine.start(experience: experience, seed: 3);
      final first = state.placements.first;
      state = engine
          .selectEndpoints(state, first.cells.first, first.cells.last)
          .state;
      final again = engine.selectEndpoints(
        state,
        first.cells.last,
        first.cells.first,
      );
      expect(again.foundWord, isNull);
      expect(again.state.foundWords, state.foundWords);
      expect(again.state.anchor, isNull);
    });
  });
}
