import 'dart:io';

import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Routine ordered steps', () {
    test('requires contiguous zero-based order', () {
      expect(OfflineFixtures.morningRoutine.steps.map((s) => s.order), [0, 1]);
      expect(
        () => Routine(
          id: OfflineFixtures.morningRoutineId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Broken Demo',
          steps: <RoutineStep>[
            RoutineStep(order: 0, instruction: 'a'),
            RoutineStep(order: 2, instruction: 'b'),
          ],
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Weight and blood-pressure observations', () {
    test('store values only and reject non-positive readings', () {
      expect(OfflineFixtures.amparoWeight.kilograms, 62.5);
      expect(
        OfflineFixtures.amparoWeight.authorId,
        IdentityFixtures.elenaPrimaryUserId,
      );
      expect(OfflineFixtures.amparoBloodPressure.systolicMmHg, 120);
      expect(OfflineFixtures.amparoBloodPressure.diastolicMmHg, 80);

      expect(
        () => WeightObservation(
          id: OfflineFixtures.weightObservationId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          kilograms: 0,
          recordedAt: OfflineFixtures.demoRecordedAt,
          authorId: IdentityFixtures.elenaPrimaryUserId,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => BloodPressureObservation(
          id: OfflineFixtures.bloodPressureObservationId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          systolicMmHg: 0,
          diastolicMmHg: 80,
          recordedAt: OfflineFixtures.demoRecordedAt,
          authorId: IdentityFixtures.elenaPrimaryUserId,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
    });

    test('observation sources expose no clinical-guidance APIs', () {
      final observationDir = Directory(
        '${Directory.current.path}/lib/src/observations',
      );
      // Identifier-shaped forbidden APIs (not prose in docs outside this package).
      final forbiddenApi = RegExp(
        r'\b(threshold|diagnose|diagnosis|interpret|interpretation|alert|'
        r'normalRange|isHigh|isLow|hypertensive)\b',
        caseSensitive: false,
      );

      final files = observationDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.dart'),
      );
      expect(files, isNotEmpty);

      for (final file in files) {
        final source = file.readAsStringSync();
        // Strip line comments before scanning for API identifiers.
        final code = source
            .split('\n')
            .map((line) {
              final idx = line.indexOf('//');
              return idx == -1 ? line : line.substring(0, idx);
            })
            .join('\n');
        expect(
          forbiddenApi.hasMatch(code),
          isFalse,
          reason: '${file.path} must stay observation-only',
        );
      }
    });
  });

  group('OfflineFixtures', () {
    test('stay on Familia Ejemplo reserved space and Demo labels', () {
      expect(
        OfflineFixtures.morningRoutine.familySpaceId,
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(OfflineFixtures.morningRoutine.title, contains('Demo'));
      expect(OfflineFixtures.gardenMemory.caption, contains('Ejemplo'));
      expect(
        OfflineFixtures.gardenMemory.lifecycleStatus,
        MemoryLifecycleStatus.approved,
      );
      expect(
        OfflineFixtures.gardenMediaMetadata.familyScopedPath,
        startsWith('${IdentityFixtures.familiaEjemploSpaceId.value}/'),
      );
      expect(
        OfflineFixtures.morningRoutine.lifecycleStatus,
        RoutineLifecycleStatus.active,
      );
      expect(
        OfflineFixtures.archivedEveningRoutine.lifecycleStatus,
        RoutineLifecycleStatus.archived,
      );
      expect(
        OfflineFixtures.archivedEveningRoutine.isPresentableToday,
        isFalse,
      );
      expect(OfflineFixtures.walkReminder.quietHours, isNotNull);
    });
  });
}
