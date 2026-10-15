import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PastimeSessionRecovery', () {
    test('save/load survives; expiry and corrupt discard safely', () async {
      final store = InMemoryPastimeSessionRecoveryStore();
      final fixedNow = DateTime.utc(2026, 10, 14, 12);
      store.now = () => fixedNow;

      final snapshot = PastimeSessionRecoverySnapshot(
        pastimeId: OfflineFixtures.sudokuDemoPastimeId,
        experienceType: SudokuPastimeExperience.wireType,
        experienceSchemaVersion: SudokuPastimeExperience.currentSchemaVersion,
        seed: 42,
        boardState: <String, Object?>{
          'values': <int>[1, 0, 0, 4],
        },
        updatedAt: fixedNow,
      );
      await store.save(snapshot);
      final loaded = await store.loadCurrent();
      expect(loaded, isNotNull);
      expect(loaded!.pastimeId, snapshot.pastimeId);
      expect(loaded.boardState['values'], [1, 0, 0, 4]);

      // Definition version change clears.
      await store.clearIfMatches(
        pastimeId: snapshot.pastimeId,
        experienceType: SudokuPastimeExperience.wireType,
        experienceSchemaVersion: 99,
      );
      expect(await store.loadCurrent(), isNull);

      await store.save(snapshot);
      store.now = () => fixedNow.add(const Duration(hours: 25));
      expect(await store.loadCurrent(), isNull);

      expect(PastimeSessionRecoverySnapshot.tryParse('nope'), isNull);
      expect(
        PastimeSessionRecoverySnapshot.tryParse(<String, Object?>{}),
        isNull,
      );
    });

    test('file store survives process-restart via path reload', () async {
      final dir = await Directory.systemTemp.createTemp('memora_pastime_rec_');
      final path = '${dir.path}/recovery.json';
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final fixedNow = DateTime.utc(2026, 10, 14, 15);
      final first = FilePastimeSessionRecoveryStore(path)..now = () => fixedNow;
      final snapshot = PastimeSessionRecoverySnapshot(
        pastimeId: OfflineFixtures.sudokuDemoPastimeId,
        experienceType: SudokuPastimeExperience.wireType,
        experienceSchemaVersion: SudokuPastimeExperience.currentSchemaVersion,
        seed: 7,
        boardState: <String, Object?>{'seed': 7, 'completedRuns': 0},
        updatedAt: fixedNow,
      );
      await first.save(snapshot);

      // New store instance = process restart against the same file.
      final restarted = FilePastimeSessionRecoveryStore(path)
        ..now = () => fixedNow;
      final loaded = await restarted.loadCurrent();
      expect(loaded, isNotNull);
      expect(loaded!.seed, 7);
      expect(loaded.boardState['completedRuns'], 0);

      await File(path).writeAsString('{not-json');
      expect(await restarted.loadCurrent(), isNull);
      expect(File(path).existsSync(), isFalse);
    });

    test('recovery is not an outbox aggregate type', () {
      expect(
        OutboxAggregateType.values.map((e) => e.name),
        isNot(contains('pastimeSession')),
      );
      expect(
        OutboxAggregateType.values.map((e) => e.name),
        isNot(contains('gameplay')),
      );
    });
  });
}
