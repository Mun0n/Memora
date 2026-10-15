import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SpiderEngine', () {
    late SpiderEngine engine;

    setUp(() {
      engine = SpiderEngine();
    });

    test('104-card multiset and deal for 1/2/4 suits', () {
      for (final suits in SpiderSuitCount.values) {
        final deck = SpiderEngine.buildDeck(suits);
        expect(deck.length, SpiderEngine.deckSize);
        final state = engine.start(
          experience: SpiderSolitairePastimeExperience(suitCount: suits),
          seed: 11,
        );
        final dealt = state.tableau.fold<int>(
          0,
          (sum, col) => sum + col.length,
        );
        expect(dealt, SpiderEngine.initialDealCount);
        expect(
          state.stock.length,
          SpiderEngine.stockDealCount * SpiderEngine.cardsPerStockDeal,
        );
        expect(state.tableau.length, SpiderEngine.columnCount);
        // Top of each column face up.
        for (final col in state.tableau) {
          expect(col.last.faceUp, isTrue);
        }
      }
    });

    test(
      'deterministic shuffle; illegal move unchanged; stock empty-column rule',
      () {
        final experience = SpiderSolitairePastimeExperience(
          suitCount: SpiderSuitCount.one,
        );
        final a = engine.start(experience: experience, seed: 21);
        final b = engine.start(experience: experience, seed: 21);
        expect(
          a.tableau.map((c) => c.map((x) => x.instanceId).toList()).toList(),
          b.tableau.map((c) => c.map((x) => x.instanceId).toList()).toList(),
        );

        // Empty a column then refuse stock deal.
        var state = a;
        // Force empty column by moving via engineered state.
        final tableau = state.tableau.map(List<SpiderCard>.from).toList();
        tableau[9] = <SpiderCard>[];
        state = state.copyWith(tableau: tableau);
        final denied = engine.dealStock(state);
        expect(denied.neutralMessage, contains('columna vacía'));
        expect(denied.state.stock.length, state.stock.length);
      },
    );

    test('hint does not mutate; undo restores; restart resets', () {
      final experience = SpiderSolitairePastimeExperience(
        suitCount: SpiderSuitCount.one,
      );
      final start = engine.start(experience: experience, seed: 5);
      final before = start.tableau
          .map((c) => c.map((x) => x.instanceId).toList())
          .toList();
      final hinted = engine.showHint(start);
      expect(
        hinted.tableau.map((c) => c.map((x) => x.instanceId).toList()).toList(),
        before,
      );

      // Deal stock when legal (no empty columns on a fresh deal).
      final dealt = engine.dealStock(start);
      expect(dealt.state.stock.length, start.stock.length - 10);
      final undone = engine.undo(dealt.state);
      expect(undone, isNotNull);
      expect(undone!.stock.length, start.stock.length);

      final restarted = engine.restart(dealt.state);
      expect(restarted.completedRuns, 0);
      expect(restarted.stock.length, start.stock.length);
    });

    test('legal same-suit descending run move onto next higher rank', () {
      // Construct a minimal legal board.
      final king = const SpiderCard(
        rank: SpiderRank.king,
        suit: SpiderSuit.spades,
        faceUp: true,
        instanceId: 1,
      );
      final queen = const SpiderCard(
        rank: SpiderRank.queen,
        suit: SpiderSuit.spades,
        faceUp: true,
        instanceId: 2,
      );
      final tableau = List.generate(10, (_) => <SpiderCard>[]);
      tableau[0] = [king];
      tableau[1] = [queen];
      // Fill other columns so stock rules aren't relevant.
      for (var i = 2; i < 10; i++) {
        tableau[i] = [
          SpiderCard(
            rank: SpiderRank.ace,
            suit: SpiderSuit.spades,
            faceUp: true,
            instanceId: 10 + i,
          ),
        ];
      }
      final state = SpiderGameState(
        suitCount: SpiderSuitCount.one,
        seed: 0,
        tableau: tableau,
        stock: const [],
        completedRuns: 0,
        selected: null,
        completed: false,
        hint: null,
      );
      final moved = engine.moveRun(state, 1, 0, 0);
      expect(moved.neutralMessage, isNull);
      expect(moved.state.tableau[0].map((c) => c.rank), [
        SpiderRank.king,
        SpiderRank.queen,
      ]);
      expect(moved.state.tableau[1], isEmpty);
    });

    test('King-to-Ace same-suit run is removed when completed', () {
      final tableau = List.generate(10, (_) => <SpiderCard>[]);
      // Column 0: King..Two face-up same suit; column 1 holds the Ace.
      tableau[0] = [
        for (var value = 13; value >= 2; value--)
          SpiderCard(
            rank: SpiderRank.fromValue(value),
            suit: SpiderSuit.spades,
            faceUp: true,
            instanceId: 100 + value,
          ),
      ];
      tableau[1] = [
        const SpiderCard(
          rank: SpiderRank.ace,
          suit: SpiderSuit.spades,
          faceUp: true,
          instanceId: 1,
        ),
      ];
      for (var i = 2; i < 10; i++) {
        tableau[i] = [
          SpiderCard(
            rank: SpiderRank.king,
            suit: SpiderSuit.hearts,
            faceUp: true,
            instanceId: 200 + i,
          ),
        ];
      }
      final state = SpiderGameState(
        suitCount: SpiderSuitCount.one,
        seed: 0,
        tableau: tableau,
        stock: const [],
        completedRuns: 0,
        selected: null,
        completed: false,
        hint: null,
      );

      final moved = engine.moveRun(state, 1, 0, 0);
      expect(moved.neutralMessage, isNull);
      expect(moved.state.completedRuns, 1);
      expect(moved.state.tableau[0], isEmpty);
      expect(moved.state.tableau[1], isEmpty);
      expect(moved.state.completed, isFalse);
    });

    test('eighth King-to-Ace removal completes the game', () {
      final tableau = List.generate(10, (_) => <SpiderCard>[]);
      tableau[0] = [
        for (var value = 13; value >= 2; value--)
          SpiderCard(
            rank: SpiderRank.fromValue(value),
            suit: SpiderSuit.spades,
            faceUp: true,
            instanceId: 300 + value,
          ),
      ];
      tableau[1] = [
        const SpiderCard(
          rank: SpiderRank.ace,
          suit: SpiderSuit.spades,
          faceUp: true,
          instanceId: 2,
        ),
      ];
      for (var i = 2; i < 10; i++) {
        tableau[i] = [
          SpiderCard(
            rank: SpiderRank.queen,
            suit: SpiderSuit.hearts,
            faceUp: true,
            instanceId: 400 + i,
          ),
        ];
      }
      final state = SpiderGameState(
        suitCount: SpiderSuitCount.one,
        seed: 0,
        tableau: tableau,
        stock: const [],
        completedRuns: SpiderEngine.runsToComplete - 1,
        selected: null,
        completed: false,
        hint: null,
      );

      final moved = engine.moveRun(state, 1, 0, 0);
      expect(moved.state.completedRuns, SpiderEngine.runsToComplete);
      expect(moved.state.completed, isTrue);
    });
  });
}
