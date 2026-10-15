import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../l10n/memora_copy.dart';
import '../../../theme/memora_theme.dart';
import '../../user_pastime_controller.dart';

/// Fixed-clue ink — high contrast and distinct from entered/revealed values.
const Color _sudokuClueInk = Color(0xFF0B3D2E);

/// Player-entered ink.
const Color _sudokuEnteredInk = Color(0xFF121212);

/// Values filled by an explicit solution reveal (not original clues).
const Color _sudokuRevealedInk = Color(0xFF5C3A1E);

/// Tap-primary Sudoku board with number tray, undo, clear, optional notes.
class SudokuBoard extends StatelessWidget {
  const SudokuBoard({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.sudokuState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final n = state.dimension;
    final selected = state.selectedIndex;
    final revealed = state.solutionRevealed;
    return Semantics(
      container: true,
      label: 'Tablero de sudoku $n por $n',
      child: Column(
        key: const Key('memora-user-sudoku-board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (revealed) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                MemoraCopy.pasatiemposSolutionShown,
                key: const Key('memora-user-sudoku-solution-status'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: MemoraTheme.highContrastInk,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxSide = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                // Prefer ≥48 dp cells; tighter viewports shrink the visual grid
                // while the number tray / actions stay ≥48 dp.
                final ideal = maxSide / n;
                final cell = ideal >= MemoraTheme.minTouchExtent
                    ? ideal.clamp(MemoraTheme.minTouchExtent, 72.0)
                    : ideal.clamp(28.0, MemoraTheme.minTouchExtent);
                final boardSide = cell * n;
                Widget grid = SizedBox(
                  width: boardSide,
                  height: boardSide,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: n,
                    ),
                    itemCount: state.cellCount,
                    itemBuilder: (context, index) {
                      return _SudokuCell(
                        state: state,
                        index: index,
                        selected: selected == index,
                        onTap: revealed
                            ? null
                            : () => controller.sudokuSelectCell(index),
                      );
                    },
                  ),
                );
                if (boardSide > constraints.maxWidth + 0.5 ||
                    boardSide > constraints.maxHeight + 0.5) {
                  grid = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(child: grid),
                  );
                }
                return Center(child: grid);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (revealed)
            FilledButton(
              key: const Key('memora-user-sudoku-solution-continue'),
              onPressed: controller.acknowledgeSudokuSolution,
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.pasatiemposSolutionContinue),
            )
          else
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var number = 1; number <= n; number++)
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: FilledButton(
                              key: Key('memora-user-sudoku-tray-$number'),
                              onPressed: () =>
                                  controller.sudokuEnterNumber(number),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(
                                  MemoraTheme.minTouchExtent,
                                  MemoraTheme.minTouchExtent,
                                ),
                              ),
                              child: Text('$number'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          key: const Key('memora-user-sudoku-undo'),
                          onPressed: controller.sudokuUndo,
                          child: const Text(MemoraCopy.pasatiemposUndo),
                        ),
                        OutlinedButton(
                          key: const Key('memora-user-sudoku-clear'),
                          onPressed: controller.sudokuClearCell,
                          child: const Text(MemoraCopy.pasatiemposClear),
                        ),
                        OutlinedButton(
                          key: const Key('memora-user-sudoku-notes'),
                          onPressed: controller.toggleNotesMode,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: controller.notesMode
                                ? const Color(0xFFE8F0EC)
                                : null,
                          ),
                          child: Text(
                            controller.notesMode
                                ? '${MemoraCopy.pasatiemposNotes} (activadas)'
                                : MemoraCopy.pasatiemposNotes,
                          ),
                        ),
                        OutlinedButton(
                          key: const Key('memora-user-sudoku-reveal'),
                          onPressed: () => _confirmReveal(context),
                          child: const Text(MemoraCopy.pasatiemposShowSolution),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReveal(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(MemoraCopy.pasatiemposShowSolutionConfirm),
        actions: [
          TextButton(
            key: const Key('memora-user-sudoku-reveal-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(MemoraCopy.pasatiemposConfirmNo),
          ),
          FilledButton(
            key: const Key('memora-user-sudoku-reveal-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(MemoraCopy.pasatiemposConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) {
      controller.sudokuRevealSolution(confirmed: true);
    }
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    required this.state,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final SudokuGameState state;
  final int index;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = state.dimension;
    final row = index ~/ n;
    final col = index % n;
    final value = state.values[index];
    final isClue = state.isClue(index);
    final isRevealedValue = state.solutionRevealed && !isClue && value != 0;
    final isEntered = !isClue && !state.solutionRevealed && value != 0;
    final engine = SudokuEngine();
    final conflict =
        value != 0 &&
        !state.solutionRevealed &&
        engine.hasConflictAt(state, index);
    final inHighlight = selected || _sameUnit(state.selectedIndex, index, n);
    final notes = state.notes[index];
    final label = StringBuffer()
      ..write('Fila ${row + 1}, columna ${col + 1}. ');
    if (isClue) {
      label.write('Pista fija original $value.');
    } else if (isRevealedValue) {
      label.write('Valor revelado de la solución $value.');
    } else if (isEntered) {
      label.write('Valor introducido $value.');
    } else if (notes.isNotEmpty) {
      label.write('Notas ${notes.toList()..sort()}.');
    } else {
      label.write('Vacía.');
    }
    if (selected) {
      label.write(' Seleccionada.');
    }
    if (conflict) {
      label.write(' $sudokuConflictMessage.');
    }

    final Color ink;
    final FontWeight weight;
    final TextDecoration? decoration;
    if (isClue) {
      ink = _sudokuClueInk;
      weight = FontWeight.w900;
      decoration = TextDecoration.underline;
    } else if (isRevealedValue) {
      ink = _sudokuRevealedInk;
      weight = FontWeight.w700;
      decoration = TextDecoration.overline;
    } else {
      ink = _sudokuEnteredInk;
      weight = FontWeight.w600;
      decoration = null;
    }

    return Semantics(
      button: !isClue && onTap != null,
      selected: selected,
      label: label.toString(),
      child: Material(
        color: selected
            ? const Color(0xFFD6E6DE)
            : isClue
            ? const Color(0xFFE4EEE9)
            : isRevealedValue
            ? const Color(0xFFF3EDE6)
            : inHighlight
            ? const Color(0xFFEEF4F1)
            : Colors.white,
        child: InkWell(
          key: Key('memora-user-sudoku-cell-$index'),
          onTap: isClue ? null : onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: conflict
                    ? const Color(0xFF5C3A1E)
                    : MemoraTheme.borderInk,
                width: selected || conflict || isClue ? 2.5 : 1,
              ),
            ),
            child: Center(
              child: value != 0
                  ? Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: weight,
                        color: ink,
                        decoration: decoration,
                        decorationThickness: 1.5,
                        decorationColor: ink,
                      ),
                    )
                  : notes.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      (notes.toList()..sort()).join(''),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  bool _sameUnit(int? selectedIndex, int index, int n) {
    if (selectedIndex == null) {
      return false;
    }
    final sr = selectedIndex ~/ n;
    final sc = selectedIndex % n;
    final r = index ~/ n;
    final c = index % n;
    if (sr == r || sc == c) {
      return true;
    }
    final boxRows = n == 9 ? 3 : (n == 6 ? 2 : 2);
    final boxCols = n == 9 ? 3 : (n == 6 ? 3 : 2);
    return sr ~/ boxRows == r ~/ boxRows && sc ~/ boxCols == c ~/ boxCols;
  }
}
