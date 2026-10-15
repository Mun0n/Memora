import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  group('wordSearchDragPreview', () {
    test('keeps forward horizontal path', () {
      final path = wordSearchDragPreview(
        start: const WordSearchCell(2, 1),
        hover: const WordSearchCell(2, 5),
        dimension: 8,
      );
      expect(path.first, const WordSearchCell(2, 1));
      expect(path.last, const WordSearchCell(2, 5));
      expect(path.length, 5);
    });

    test('keeps reverse vertical path', () {
      final path = wordSearchDragPreview(
        start: const WordSearchCell(5, 3),
        hover: const WordSearchCell(1, 3),
        dimension: 8,
      );
      expect(path.first, const WordSearchCell(5, 3));
      expect(path.last, const WordSearchCell(1, 3));
    });

    test('keeps diagonal path', () {
      final path = wordSearchDragPreview(
        start: const WordSearchCell(0, 0),
        hover: const WordSearchCell(3, 3),
        dimension: 8,
      );
      expect(path.map((c) => '${c.row},${c.col}').toList(), [
        '0,0',
        '1,1',
        '2,2',
        '3,3',
      ]);
    });

    test('snaps off-axis hover onto nearest straight ray', () {
      final path = wordSearchDragPreview(
        start: const WordSearchCell(2, 2),
        hover: const WordSearchCell(5, 3), // nearer vertical than diagonal
        dimension: 8,
      );
      expect(WordSearchEngine.straightPath(path.first, path.last), isNotNull);
      expect(path.first, const WordSearchCell(2, 2));
    });
  });

  group('wordSearchCellAt', () {
    test('maps local offsets to cells', () {
      expect(
        wordSearchCellAt(dx: 10, dy: 10, cellSize: 40, dimension: 8),
        const WordSearchCell(0, 0),
      );
      expect(
        wordSearchCellAt(dx: 45, dy: 85, cellSize: 40, dimension: 8),
        const WordSearchCell(2, 1),
      );
      expect(
        wordSearchCellAt(dx: -1, dy: 10, cellSize: 40, dimension: 8),
        isNull,
      );
    });
  });
}
