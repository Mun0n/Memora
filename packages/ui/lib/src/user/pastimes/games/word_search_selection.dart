import 'package:domain/domain.dart';

/// Eight straight directions used by the word-search engine.
const List<(int, int)> wordSearchDirections = <(int, int)>[
  (0, 1),
  (0, -1),
  (1, 0),
  (-1, 0),
  (1, 1),
  (1, -1),
  (-1, 1),
  (-1, -1),
];

/// Maps a drag hover to an eight-direction preview path from [start].
///
/// Prefer the exact straight path when the hover cell is already aligned;
/// otherwise snap to the nearest valid ray so the preview follows the finger.
List<WordSearchCell> wordSearchDragPreview({
  required WordSearchCell start,
  required WordSearchCell hover,
  required int dimension,
}) {
  if (start == hover) {
    return <WordSearchCell>[start];
  }
  final direct = WordSearchEngine.straightPath(start, hover);
  if (direct != null) {
    return direct;
  }

  WordSearchCell? best;
  var bestDist = 1 << 30;
  for (final direction in wordSearchDirections) {
    final (dr, dc) = direction;
    for (var step = 1; ; step++) {
      final row = start.row + dr * step;
      final col = start.col + dc * step;
      if (row < 0 || row >= dimension || col < 0 || col >= dimension) {
        break;
      }
      final candidate = WordSearchCell(row, col);
      final dist =
          (candidate.row - hover.row).abs() + (candidate.col - hover.col).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }
  }
  if (best == null) {
    return <WordSearchCell>[start];
  }
  return WordSearchEngine.straightPath(start, best) ?? <WordSearchCell>[start];
}

/// Resolves a local offset inside a square board into a cell, or null if outside.
WordSearchCell? wordSearchCellAt({
  required double dx,
  required double dy,
  required double cellSize,
  required int dimension,
}) {
  if (cellSize <= 0) {
    return null;
  }
  final col = (dx / cellSize).floor();
  final row = (dy / cellSize).floor();
  if (row < 0 || row >= dimension || col < 0 || col >= dimension) {
    return null;
  }
  return WordSearchCell(row, col);
}
