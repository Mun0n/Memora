import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../l10n/memora_copy.dart';
import '../../../theme/memora_theme.dart';
import '../../user_pastime_controller.dart';
import '../platform/preferred_orientations_port.dart';
import 'playing_card_face.dart';

/// Tap-primary Spider Solitaire tableau with landscape lock and card faces.
class SpiderBoard extends StatefulWidget {
  const SpiderBoard({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  State<SpiderBoard> createState() => _SpiderBoardState();
}

class _SpiderBoardState extends State<SpiderBoard> {
  PreferredOrientationsPort get _orientations => widget.controller.orientations;

  @override
  void initState() {
    super.initState();
    _orientations.lockLandscape();
  }

  @override
  void dispose() {
    _orientations.restoreAppDefaults();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.spiderState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final selected = state.selected;
    final hint = state.hint;
    const cardWidth = 72.0;
    const cardHeight = 96.0;
    const overlap = 28.0;
    var tallest = 1;
    for (final column in state.tableau) {
      tallest = math.max(tallest, column.length);
    }
    final stackHeight = cardHeight + (tallest - 1) * overlap;
    final tableauHeight = MemoraTheme.minTouchExtent + 4 + stackHeight;

    return Semantics(
      container: true,
      label:
          'Solitario Spider, ${state.completedRuns} de '
          '${SpiderEngine.runsToComplete} secuencias completadas',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final body = Column(
            key: const Key('memora-user-spider-board'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Secuencias: ${state.completedRuns}/'
                '${SpiderEngine.runsToComplete}',
                key: const Key('memora-user-spider-status'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: MemoraTheme.minTouchExtent,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var col = 1; col <= SpiderEngine.columnCount; col++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          key: Key('memora-user-spider-goto-$col'),
                          onPressed: () => controller.spiderTapColumn(col - 1),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              MemoraTheme.minTouchExtent,
                              MemoraTheme.minTouchExtent,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            '${MemoraCopy.pasatiemposGoToColumn} $col',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _BoardOverview(state: state, selected: selected),
              const SizedBox(height: 6),
              SizedBox(
                height: tableauHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var col = 0; col < SpiderEngine.columnCount; col++)
                      _SpiderColumn(
                        column: col,
                        cards: state.tableau[col],
                        selected: selected,
                        hint: hint,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        overlap: overlap,
                        onCardTap: (index) =>
                            controller.spiderTapCard(col, index),
                        onColumnTap: () => controller.spiderTapColumn(col),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('memora-user-spider-deal'),
                    onPressed: state.stock.isEmpty
                        ? null
                        : controller.spiderDealStock,
                    child: Text(
                      '${MemoraCopy.pasatiemposDealStock}'
                      ' (${state.stock.length ~/ SpiderEngine.cardsPerStockDeal})',
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('memora-user-spider-undo'),
                    onPressed: controller.spiderUndo,
                    child: const Text(MemoraCopy.pasatiemposUndo),
                  ),
                  OutlinedButton(
                    key: const Key('memora-user-spider-hint'),
                    onPressed: controller.spiderShowHint,
                    child: const Text(MemoraCopy.pasatiemposShowHint),
                  ),
                ],
              ),
            ],
          );

          // Always scrollable so portrait/landscape shell chrome cannot trap.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: body,
            ),
          );
        },
      ),
    );
  }
}

class _BoardOverview extends StatelessWidget {
  const _BoardOverview({required this.state, required this.selected});

  final SpiderGameState state;
  final SpiderSelection? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vista general del tablero',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var col = 0; col < SpiderEngine.columnCount; col++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: MemoraTheme.borderInk,
                  width: selected?.column == col ? 2 : 1,
                ),
                color: selected?.column == col
                    ? const Color(0xFFD6E6DE)
                    : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  '${col + 1}:${state.tableau[col].length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpiderColumn extends StatelessWidget {
  const _SpiderColumn({
    required this.column,
    required this.cards,
    required this.selected,
    required this.hint,
    required this.cardWidth,
    required this.cardHeight,
    required this.overlap,
    required this.onCardTap,
    required this.onColumnTap,
  });

  final int column;
  final List<SpiderCard> cards;
  final SpiderSelection? selected;
  final SpiderHint? hint;
  final double cardWidth;
  final double cardHeight;
  final double overlap;
  final void Function(int index) onCardTap;
  final VoidCallback onColumnTap;

  @override
  Widget build(BuildContext context) {
    final stackHeight = cards.isEmpty
        ? cardHeight
        : cardHeight + (cards.length - 1) * overlap;
    return SizedBox(
      width: cardWidth + 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Columna ${column + 1}, destino',
            child: InkWell(
              key: Key('memora-user-spider-column-$column'),
              onTap: onColumnTap,
              child: Container(
                height: MemoraTheme.minTouchExtent,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: MemoraTheme.borderInk, width: 2),
                  color: hint?.toColumn == column
                      ? const Color(0xFFE8F0EC)
                      : Colors.white,
                ),
                child: Text(
                  '${column + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: stackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (cards.isEmpty)
                  Positioned(
                    top: 0,
                    left: 4,
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: MemoraTheme.borderInk,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFF0F0EA),
                        ),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < cards.length; i++)
                    Positioned(
                      top: i * overlap,
                      left: 4,
                      child: _SpiderCardTile(
                        column: column,
                        index: i,
                        card: cards[i],
                        selected:
                            selected?.column == column &&
                            selected!.fromIndex <= i,
                        hinted:
                            hint != null &&
                            hint!.fromColumn == column &&
                            i >= hint!.fromIndex,
                        width: cardWidth,
                        height: cardHeight,
                        onTap: () => onCardTap(i),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiderCardTile extends StatelessWidget {
  const _SpiderCardTile({
    required this.column,
    required this.index,
    required this.card,
    required this.selected,
    required this.hinted,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final int column;
  final int index;
  final SpiderCard card;
  final bool selected;
  final bool hinted;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: card.faceUp,
      selected: selected,
      label:
          '${card.semanticLabel}, columna ${column + 1}'
          '${selected ? ', seleccionada' : ''}'
          '${hinted ? ', movimiento sugerido' : ''}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('memora-user-spider-card-$column-$index'),
          onTap: card.faceUp ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: PlayingCardFace(
            key: Key('memora-user-spider-card-face-$column-$index'),
            card: card,
            selected: selected,
            hinted: hinted,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }
}
