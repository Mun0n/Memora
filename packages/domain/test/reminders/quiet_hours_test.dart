import 'dart:io';

import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('QuietHours', () {
    test('same-day window suppresses inside and allows outside', () {
      final window = QuietHours(
        startMinuteOfDay: 13 * 60,
        endMinuteOfDay: 15 * 60,
      );
      expect(window.containsMinuteOfDay(13 * 60), isTrue);
      expect(window.containsMinuteOfDay(14 * 60 + 30), isTrue);
      expect(window.containsMinuteOfDay(15 * 60), isFalse);
      expect(window.containsMinuteOfDay(12 * 60), isFalse);
    });

    test('overnight Demo window suppresses at night and early morning', () {
      final window = OfflineFixtures.demoQuietHours;
      expect(
        window.containsLocalDateTime(DateTime(2026, 10, 10, 23, 0)),
        isTrue,
      );
      expect(
        window.containsLocalDateTime(DateTime(2026, 10, 10, 6, 59)),
        isTrue,
      );
      expect(
        window.containsLocalDateTime(DateTime(2026, 10, 10, 7, 0)),
        isFalse,
      );
      expect(
        window.containsLocalDateTime(DateTime(2026, 10, 10, 17, 30)),
        isFalse,
      );
    });

    test('reminder convenience suppression uses quiet hours only', () {
      final reminder = OfflineFixtures.walkReminder;
      expect(
        reminder.isConveniencePromptSuppressed(DateTime(2026, 10, 10, 23, 15)),
        isTrue,
      );
      expect(
        reminder.isConveniencePromptSuppressed(DateTime(2026, 10, 10, 17, 30)),
        isFalse,
      );
      final open = reminder.copyWith(clearQuietHours: true);
      expect(
        open.isConveniencePromptSuppressed(DateTime(2026, 10, 10, 23, 15)),
        isFalse,
      );
    });

    test('reminder sources expose no emergency or medical coverage APIs', () {
      final reminderDir = Directory(
        '${Directory.current.path}/lib/src/reminders',
      );
      // Identifier-shaped forbidden APIs (line + block comments stripped).
      final forbiddenApi = RegExp(
        r'\b(emergency|urgente|cobertura|dispatchAlarm|medicalAlert|'
        r'diagnose|diagnosis|tratamiento|treatmentPlan)\b',
        caseSensitive: false,
      );

      final files = reminderDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.dart'),
      );
      expect(files, isNotEmpty);

      for (final file in files) {
        final source = file.readAsStringSync();
        final withoutBlock = source.replaceAll(
          RegExp(r'/\*.*?\*/', dotAll: true),
          '',
        );
        final code = withoutBlock
            .split('\n')
            .map((line) {
              final trimmed = line.trimLeft();
              if (trimmed.startsWith('//')) {
                return '';
              }
              final idx = line.indexOf('//');
              return idx == -1 ? line : line.substring(0, idx);
            })
            .join('\n');
        expect(
          forbiddenApi.hasMatch(code),
          isFalse,
          reason: '${file.path} must stay convenience-prompt only',
        );
      }
    });
  });

  group('ConfigureReminder', () {
    test('caregiver configures quiet hours; contributor denied', () async {
      final saved = <Reminder>[];
      final repo = _ListReminderRepository(saved);
      final configure = ConfigureReminder(repo);

      final created = await configure.create(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.walkReminderId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Paseo corto Demo',
        scheduledAt: OfflineFixtures.walkReminder.scheduledAt,
        quietHours: OfflineFixtures.demoQuietHours,
        idempotencyKey: OfflineFixtures.walkReminderSaveKey,
      );
      expect(created.quietHours, isNotNull);

      await expectLater(
        configure.edit(
          actor: IdentityFixtures.luciaContributorMembership,
          id: OfflineFixtures.walkReminderId,
          title: 'Denied Demo',
          idempotencyKey: IdempotencyKey('demo-reminder-contributor-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });
  });
}

final class _ListReminderRepository implements ReminderRepository {
  _ListReminderRepository(this.items);

  final List<Reminder> items;

  @override
  Future<Reminder> save({
    required Reminder reminder,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = reminder.copyWith(syncState: SyncState.pending);
    final index = items.indexWhere((r) => r.id == pending.id);
    if (index == -1) {
      items.add(pending);
    } else {
      items[index] = pending;
    }
    return pending;
  }

  @override
  Future<Reminder?> findById(ReminderId id) async {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<Reminder>> listForFamily(FamilySpaceId familySpaceId) async {
    return items
        .where((r) => r.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  @override
  Future<Reminder> softDelete({
    required ReminderId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}
