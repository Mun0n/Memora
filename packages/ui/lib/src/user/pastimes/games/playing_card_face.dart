import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../theme/memora_theme.dart';

/// Accessible playing-card face rendered with Flutter primitives (no SDK).
///
/// Suit letter/name always accompany red/black colour. Face-down backs are
/// patterned without exposing rank.
class PlayingCardFace extends StatelessWidget {
  const PlayingCardFace({
    super.key,
    required this.card,
    this.selected = false,
    this.hinted = false,
    this.width = 72,
    this.height = 96,
    this.compact = false,
  });

  final SpiderCard card;
  final bool selected;
  final bool hinted;
  final double width;
  final double height;
  final bool compact;

  static const Color _redSuit = Color(0xFF9B1C1C);
  static const Color _blackSuit = Color(0xFF121212);
  static const Color _backInk = Color(0xFF1F4B3A);
  static const Color _backFill = Color(0xFF2A5F4A);

  static bool isRedSuit(SpiderSuit suit) =>
      suit == SpiderSuit.hearts || suit == SpiderSuit.diamonds;

  static String suitMark(SpiderSuit suit) => switch (suit) {
    SpiderSuit.spades => '♠',
    SpiderSuit.hearts => '♥',
    SpiderSuit.diamonds => '♦',
    SpiderSuit.clubs => '♣',
  };

  @override
  Widget build(BuildContext context) {
    final borderWidth = selected ? 3.0 : 1.5;
    final borderColor = selected
        ? MemoraTheme.accentBand
        : hinted
        ? const Color(0xFF3D6B58)
        : MemoraTheme.borderInk;
    return AnimatedContainer(
      duration: Duration.zero,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: card.faceUp ? Colors.white : _backFill,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(6),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 0,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: card.faceUp
          ? _FaceUp(card: card, compact: compact)
          : const _Back(),
    );
  }
}

class _FaceUp extends StatelessWidget {
  const _FaceUp({required this.card, required this.compact});

  final SpiderCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final red = PlayingCardFace.isRedSuit(card.suit);
    final ink = red ? PlayingCardFace._redSuit : PlayingCardFace._blackSuit;
    final mark = PlayingCardFace.suitMark(card.suit);
    final cornerSize = compact ? 11.0 : 13.0;
    final centerSize = compact ? 22.0 : 28.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 64,
          height: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.rank.symbol,
                    style: TextStyle(
                      fontSize: cornerSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    mark,
                    style: TextStyle(
                      fontSize: cornerSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      fontSize: cornerSize - 2,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: ink,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    mark,
                    style: TextStyle(
                      fontSize: centerSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: ink,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  card.suit.labelEs.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: cornerSize - 3,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PlayingCardFace._backInk, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5F4A), Color(0xFF1F4B3A), Color(0xFF2A5F4A)],
        ),
      ),
      child: CustomPaint(painter: _BackPatternPainter()),
    );
  }
}

class _BackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    const step = 8.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
