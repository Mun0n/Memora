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
