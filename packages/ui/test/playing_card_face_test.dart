import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets(
    'renders every rank and suit with face-down distinct from face-up',
    (tester) async {
      final cards = <SpiderCard>[
        for (final suit in SpiderSuit.values)
          for (final rank in SpiderRank.values)
            SpiderCard(
              rank: rank,
              suit: suit,
              faceUp: true,
              instanceId: rank.value * 10 + suit.index,
            ),
        const SpiderCard(
          rank: SpiderRank.ace,
          suit: SpiderSuit.spades,
          faceUp: false,
          instanceId: 999,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final card in cards)
                    PlayingCardFace(
                      key: Key('card-${card.instanceId}'),
                      card: card,
                      width: 56,
                      height: 76,
                      compact: true,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayingCardFace), findsNWidgets(cards.length));
      expect(find.text('♠'), findsWidgets);
      expect(find.text('♥'), findsWidgets);
      expect(find.text('♦'), findsWidgets);
      expect(find.text('♣'), findsWidgets);
      expect(find.text('A'), findsWidgets);
      expect(find.text('K'), findsWidgets);
      expect(PlayingCardFace.isRedSuit(SpiderSuit.hearts), isTrue);
      expect(PlayingCardFace.isRedSuit(SpiderSuit.spades), isFalse);
    },
  );
}
