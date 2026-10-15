import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../l10n/memora_copy.dart';
import '../../../theme/memora_theme.dart';
import '../../user_pastime_controller.dart';
import 'word_search_selection.dart';

/// Spanish word-search board: press-and-drag primary, tap endpoints as fallback.
class WordSearchBoard extends StatefulWidget {
  const WordSearchBoard({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  State<WordSearchBoard> createState() => _WordSearchBoardState();
}

class _WordSearchBoardState extends State<WordSearchBoard> {
  WordSearchCell? _dragStart;
  List<WordSearchCell> _preview = const <WordSearchCell>[];
  Offset? _lastGlobal;
  double _cellSize = 48;
  int _dimension = 8;
  final GlobalKey _gridKey = GlobalKey();

  UserPastimeController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.wordSearchState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final n = state.dimension;
    _dimension = n;
    return Semantics(
      container: true,
      label: 'Sopa de letras $n por $n',
      child: Column(
        key: const Key('memora-user-wordsearch-board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            MemoraCopy.pasatiemposWordList,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final word in state.words)
                Semantics(
                  label: state.foundWords.contains(word)
                      ? '$word, encontrada'
                      : '$word, pendiente',
                  child: Chip(
                    key: Key('memora-user-wordsearch-word-$word'),
                    avatar: Icon(
                      state.foundWords.contains(word)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    label: Text(
                      word,
                      style: TextStyle(
                        decoration: state.foundWords.contains(word)
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: state.foundWords.contains(word)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Reserve status space so showing the preview cannot reflow the grid
          // mid-drag (which would break global→cell hit mapping).
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: _preview.length > 1
                ? Text(
                    'Selección en curso (${_preview.length} letras)',
                    key: const Key('memora-user-wordsearch-drag-preview'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = (constraints.maxWidth / n).clamp(40.0, 56.0);
                _cellSize = cell;
                final boardSide = cell * n;
                Widget grid = SizedBox(
                  key: _gridKey,
                  width: boardSide,
                  height: boardSide,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: n,
                    ),
                    itemCount: n * n,
                    itemBuilder: (context, index) {
                      final row = index ~/ n;
                      final col = index % n;
                      final cellCoord = WordSearchCell(row, col);
                      final letter = state.grid[row][col];
                      final isAnchor = state.anchor == cellCoord;
                      final inPreview = _preview.contains(cellCoord);
                      final inFound = _cellInFound(state, cellCoord);
                      return Semantics(
                        key: Key('memora-user-wordsearch-cell-$row-$col'),
                        button: true,
                        selected: isAnchor || inPreview,
                        label:
                            'Fila ${row + 1}, columna ${col + 1}, letra $letter'
                            '${isAnchor ? ', inicio de selección' : ''}'
                            '${inPreview ? ', en vista previa' : ''}'
                            '${inFound ? ', en palabra encontrada' : ''}',
                        onTap: state.completed || _dragStart != null
                            ? null
                            : () => controller.wordSearchTapCell(cellCoord),
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: state.completed
                              ? null
                              : (event) {
                                  _lastGlobal = event.position;
                                  setState(() {
                                    _dragStart = cellCoord;
                                    _preview = <WordSearchCell>[cellCoord];
                                  });
                                },
                          onPointerMove: state.completed
                              ? null
                              : (event) {
                                  if (_dragStart != null) {
                                    _updateDrag(event.position);
                                  }
                                },
                          onPointerUp: state.completed
                              ? null
                              : (event) => _handlePointerUp(event.position),
                          onPointerCancel: state.completed
                              ? null
                              : (_) => _clearDrag(),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: inPreview
                                  ? const Color(0xFFB8D4C8)
                                  : isAnchor
                                  ? const Color(0xFFD6E6DE)
                                  : inFound
                                  ? const Color(0xFFE8F0EC)
                                  : Colors.white,
                              border: Border.all(
                                color: MemoraTheme.borderInk,
                                width: isAnchor || inPreview ? 2.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: inFound || inPreview
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  decoration: inFound
                                      ? TextDecoration.underline
                                      : inPreview
                                      ? TextDecoration.overline
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
                if (boardSide > constraints.maxWidth ||
                    boardSide > constraints.maxHeight) {
                  grid = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: _dragStart != null
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    child: SingleChildScrollView(
                      physics: _dragStart != null
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      child: grid,
                    ),
                  );
                }
                return Center(child: grid);
              },
            ),
          ),
          if (state.anchor != null || _dragStart != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('memora-user-wordsearch-cancel'),
              onPressed: () {
                _clearDrag();
                controller.wordSearchClearSelection();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.pasatiemposCancelSelection),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePointerUp(Offset global) {
    _lastGlobal = global;
    final start = _dragStart;
    if (start == null) {
      return;
    }
    final end = _cellForGlobal(global) ?? _preview.lastOrNull;
    if (end != null && end != start) {
      _updateDrag(global);
      _endDrag();
    } else if (_preview.length > 1) {
      _endDrag();
    } else {
      _clearDrag();
      // Short press — tap-endpoint accessibility path.
      controller.wordSearchTapCell(start);
    }
  }

  void _updateDrag(Offset global) {
    final start = _dragStart;
    if (start == null) {
      return;
    }
    _lastGlobal = global;
    final hover = _cellForGlobal(global) ?? _preview.lastOrNull;
    if (hover == null) {
      return;
    }
    final next = wordSearchDragPreview(
      start: start,
      hover: hover,
      dimension: _dimension,
    );
    if (!_samePath(next, _preview)) {
      setState(() => _preview = next);
    }
  }

  void _endDrag() {
    final start = _dragStart;
    if (start == null) {
      return;
    }
    final global = _lastGlobal;
    final end =
        (global == null ? null : _cellForGlobal(global)) ??
        (_preview.isNotEmpty ? _preview.last : start);
    final path = wordSearchDragPreview(
      start: start,
      hover: end,
      dimension: _dimension,
    );
    final submitEnd = path.isNotEmpty ? path.last : end;
    _clearDrag();
    if (submitEnd == start) {
      controller.wordSearchTapCell(start);
      return;
    }
    controller.wordSearchSelectEndpoints(start, submitEnd);
  }

  void _clearDrag() {
    _lastGlobal = null;
    if (_dragStart == null && _preview.isEmpty) {
      return;
    }
    setState(() {
      _dragStart = null;
      _preview = const <WordSearchCell>[];
    });
  }

  WordSearchCell? _cellForGlobal(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    final local = box.globalToLocal(global);
    return wordSearchCellAt(
      dx: local.dx,
      dy: local.dy,
      cellSize: _cellSize,
      dimension: _dimension,
    );
  }

  bool _cellInFound(WordSearchGameState state, WordSearchCell cell) {
    for (final placement in state.placements) {
      if (!state.foundWords.contains(placement.word)) {
        continue;
      }
      if (placement.cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  bool _samePath(List<WordSearchCell> a, List<WordSearchCell> b) {
    if (a.length != b.length) {
      return false;
    }
    return _listEquals(a, b);
  }

  bool _listEquals(List<WordSearchCell> a, List<WordSearchCell> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
