import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PastimeCodec', () {
    test('legacy payload without experience decodes as guided', () {
      final decoded = PastimeCodec.decodePastime(
        aggregateId: OfflineFixtures.radioPastimeId.value,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId.value,
        payload: <String, Object?>{
          'title': 'Radio Demo',
          'instruction': 'Escuchar la radio Ejemplo un rato en el sillón.',
          'displayOrder': 0,
          'lifecycle': 'active',
          'tombstoned': false,
          'version': 1,
        },
        version: AggregateVersion(1),
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(decoded.experience, isA<GuidedPastimeExperience>());
      expect(decoded.isActiveForViewing, isTrue);
    });

    test('new experiences round-trip; unknown quarantines', () {
      final sudoku = OfflineFixtures.sudokuDemoPastime;
      final encoded = PastimeCodec.encodePayload(sudoku);
      expect(encoded['experience'], isA<Map>());
      final decoded = PastimeCodec.decodePastime(
        aggregateId: sudoku.id.value,
        familySpaceId: sudoku.familySpaceId.value,
        payload: encoded,
        version: sudoku.version,
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(decoded.experience, isA<SudokuPastimeExperience>());
      expect(
        (decoded.experience as SudokuPastimeExperience).puzzlePackId,
        SudokuPuzzlePackCatalog.starter4,
      );

      final bad = PastimeCodec.decodePastime(
        aggregateId: sudoku.id.value,
        familySpaceId: sudoku.familySpaceId.value,
        payload: <String, Object?>{
          ...encoded,
          'experience': <String, Object?>{
            'type': 'sudoku',
            'schemaVersion': 1,
            'boardSize': '4x4',
            'puzzlePackId': 'remote_evil',
          },
        },
        version: AggregateVersion(2),
        tombstoned: false,
        syncState: SyncState.synced,
      );
      expect(bad.experience, isA<QuarantinedPastimeExperience>());
      expect(bad.isActiveForViewing, isFalse);
    });
  });
}
