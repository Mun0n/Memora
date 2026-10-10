import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('SyncStatusLabels maps all SyncState values to Spanish copy', () {
    expect(
      SyncStatusLabels.forSyncState(SyncState.local),
      MemoraCopy.syncLocal,
    );
    expect(
      SyncStatusLabels.forSyncState(SyncState.pending),
      MemoraCopy.syncPending,
    );
    expect(
      SyncStatusLabels.forSyncState(SyncState.synced),
      MemoraCopy.syncSynced,
    );
    expect(
      SyncStatusLabels.forSyncState(SyncState.conflicted),
      contains('conflicto'),
    );
    expect(
      SyncStatusLabels.forSyncState(SyncState.failed),
      contains('sincronizar'),
    );
  });

  test('MemoraCopy locale tag is Spanish-first', () {
    expect(MemoraCopy.localeTag, 'es');
    expect(MemoraCopy.demoBanner, contains('DEMOSTRACIÓN'));
    expect(MemoraCopy.reminderConvenienceNotice, contains('comodidad'));
    expect(
      MemoraCopy.reminderConvenienceNotice,
      isNot(contains('emergency coverage')),
    );
    expect(MemoraCopy.observationDisclaimer, contains('no interpreta'));
    expect(MemoraCopy.helpAboutDisclaimer, contains('emergencias'));
    expect(
      MemoraCopy.observationDisclaimer.toLowerCase(),
      isNot(contains('umbral')),
    );
    expect(
      MemoraCopy.observationDisclaimer.toLowerCase(),
      isNot(contains('alerta')),
    );
    expect(MemoraCopy.sessionDemoTitle, contains('demostración'));
    expect(MemoraCopy.syncPushAction, contains('Enviar'));
    expect(MemoraCopy.privacyExportAction, contains('exportación'));
    expect(MemoraCopy.privacyAuditNote.toLowerCase(), contains('tokens'));
    expect(
      MemoraCopy.sessionCredentialNamesHint,
      contains(RemoteCredentialNames.supabaseUrl),
    );
    expect(
      MemoraCopy.sessionCredentialNamesHint,
      isNot(contains('service_role')),
    );
  });

  test(
    'SyncPresentationController conflict summary never dumps health keys',
    () {
      final conflict = SyncConflict(
        id: '01932f00-0006-7000-8000-000000000901',
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        aggregateType: OutboxAggregateType.weightObservation,
        aggregateId: OfflineFixtures.amparoWeight.id.value,
        localVersion: AggregateVersion(1),
        remoteVersion: AggregateVersion(1),
        localPayload: const {'kilograms': 62.5},
        remotePayload: const {'kilograms': 99.9},
        detectedAt: DateTime.utc(2026, 10, 10),
      );
      final summary = SyncPresentationController.conflictSummary(conflict);
      expect(summary, contains('Observación'));
      expect(summary, isNot(contains('62.5')));
      expect(summary, isNot(contains('99.9')));
      expect(summary, isNot(contains('kilograms')));
    },
  );

  test('DemoIds produce memory and observation ids', () {
    final ids = DemoIds(start: 0x800);
    expect(ids.nextMemoryId().value, startsWith('01932f00-0004-7000-8000-'));
    expect(
      ids.nextObservationId().value,
      startsWith('01932f00-0004-7000-8000-'),
    );
  });

  test('SpanishDateFormat formats Demo civil time', () {
    final stamp = DateTime(2026, 10, 10, 9, 30);
    expect(
      SpanishDateFormat.formatDateTime(stamp),
      'sábado, 10 de octubre de 2026 · 09:30',
    );
  });

  test('DemoIds produce valid reserved-style UUIDs', () {
    final ids = DemoIds(start: 0x700);
    final routineId = ids.nextRoutineId();
    expect(routineId.value, startsWith('01932f00-0004-7000-8000-'));
    final key = ids.nextIdempotencyKey('test');
    expect(key.value, contains('demo-ui-test'));
  });
}
