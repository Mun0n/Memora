import 'package:domain/domain.dart';

import '../offline/in_memory_offline_store.dart';
import 'conversation_topic_codec.dart';

/// Bridges [InMemoryOfflineStore] aggregates to [SyncEngine] ports.
final class OfflineSyncBridge implements SyncPayloadLoader, SyncApplyHandler {
  OfflineSyncBridge(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<SyncEnvelope?> load(OutboxOperation operation) async {
    switch (operation.aggregateType) {
      case OutboxAggregateType.routine:
        final routine = _store.routineById(RoutineId(operation.aggregateId));
        if (routine == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: routine.familySpaceId.value,
          payload: <String, Object?>{
            'title': routine.title,
            'lifecycle': routine.lifecycleStatus.wireName,
            'steps': routine.steps
                .map(
                  (s) => <String, Object?>{
                    'order': s.order,
                    'instruction': s.instruction,
                  },
                )
                .toList(growable: false),
            'tombstoned': routine.isDeleted,
            'version': routine.version.value,
          },
        );
      case OutboxAggregateType.reminder:
        final reminder = _store.reminderById(ReminderId(operation.aggregateId));
        if (reminder == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: reminder.familySpaceId.value,
          payload: <String, Object?>{
            'title': reminder.title,
            'scheduledAt': reminder.scheduledAt.toUtc().toIso8601String(),
            'tombstoned': reminder.isDeleted,
            'version': reminder.version.value,
          },
        );
      case OutboxAggregateType.memory:
        final memory = _store.memoryById(MemoryId(operation.aggregateId));
        if (memory == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: memory.familySpaceId.value,
          payload: <String, Object?>{
            'caption': memory.caption,
            'dateContext': memory.dateContext,
            'displayOrder': memory.displayOrder,
            'lifecycle': memory.lifecycleStatus.wireName,
            'tombstoned': memory.isDeleted,
            'version': memory.version.value,
            if (memory.media != null)
              'mediaPath': memory.media!.familyScopedPath,
          },
        );
      case OutboxAggregateType.pastime:
        final pastime = _store.pastimeById(PastimeId(operation.aggregateId));
        if (pastime == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: pastime.familySpaceId.value,
          payload: <String, Object?>{
            'title': pastime.title,
            'instruction': pastime.instruction,
            'displayOrder': pastime.displayOrder,
            'lifecycle': pastime.lifecycleStatus.wireName,
            'tombstoned': pastime.isDeleted,
            'version': pastime.version.value,
          },
        );
      case OutboxAggregateType.conversationTopic:
        final topic = _store.conversationTopicById(
          ConversationTopicId(operation.aggregateId),
        );
        if (topic == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: topic.familySpaceId.value,
          payload: _conversationTopicPayload(topic),
        );
      case OutboxAggregateType.weightObservation:
        final observation = _store.weightById(
          ObservationId(operation.aggregateId),
        );
        if (observation == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: observation.familySpaceId.value,
          payload: <String, Object?>{
            'kilograms': observation.kilograms,
            'recordedAt': observation.recordedAt.toUtc().toIso8601String(),
            'authorId': observation.authorId.value,
            'corrects': observation.correctsObservationId?.value,
            'tombstoned': observation.isDeleted,
            'version': observation.version.value,
          },
        );
      case OutboxAggregateType.bloodPressureObservation:
        final observation = _store.bloodPressureById(
          ObservationId(operation.aggregateId),
        );
        if (observation == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: observation.familySpaceId.value,
          payload: <String, Object?>{
            'systolic': observation.systolicMmHg,
            'diastolic': observation.diastolicMmHg,
            'recordedAt': observation.recordedAt.toUtc().toIso8601String(),
            'authorId': observation.authorId.value,
            'corrects': observation.correctsObservationId?.value,
            'tombstoned': observation.isDeleted,
            'version': observation.version.value,
          },
        );
      case OutboxAggregateType.routineProgress:
        final progress = _store.progressById(
          RoutineProgressId(operation.aggregateId),
        );
        if (progress == null) {
          return null;
        }
        return SyncEnvelope(
          operation: operation,
          familySpaceId: progress.familySpaceId.value,
          payload: <String, Object?>{
            'routineId': progress.routineId.value,
            'localDate': progress.localDate.toIso8601String(),
            'tombstoned': progress.isDeleted,
            'version': progress.version.value,
          },
        );
    }
  }

  @override
  Future<void> markLocalSynced(
    OutboxOperation operation,
    AggregateVersion remoteVersion,
  ) async {
    await _setSyncState(operation, SyncState.synced, version: remoteVersion);
  }

  @override
  Future<void> markLocalConflicted(OutboxOperation operation) async {
    await _setSyncState(operation, SyncState.conflicted);
  }

  @override
  Future<void> markLocalFailed(OutboxOperation operation) async {
    await _setSyncState(operation, SyncState.failed);
  }

  @override
  Future<SyncApplyOutcome> applyRemote(
    RemoteRecord record, {
    bool preserveBoth = false,
  }) async {
    switch (record.aggregateType) {
      case OutboxAggregateType.routine:
        final local = _store.routineById(RoutineId(record.aggregateId));
        if (local != null &&
            !local.version.isBefore(record.version) &&
            !preserveBoth) {
          return SyncApplyOutcome.skipped;
        }
        final steps = (record.payload['steps'] as List<dynamic>? ?? const [])
            .map((raw) {
              final map = Map<String, Object?>.from(raw as Map);
              return RoutineStep(
                order: map['order']! as int,
                instruction: map['instruction']! as String,
              );
            })
            .toList();
        final applied = Routine(
          id: RoutineId(record.aggregateId),
          familySpaceId: FamilySpaceId(record.familySpaceId),
          title: record.payload['title']! as String,
          steps: steps.isEmpty
              ? [RoutineStep(order: 0, instruction: 'Paso Demo')]
              : steps,
          lifecycleStatus: RoutineLifecycleStatus.parse(
            record.payload['lifecycle'] as String? ?? 'active',
          ),
          version: record.version,
          syncState: SyncState.synced,
          tombstone: record.tombstoned
              ? Tombstone(
                  aggregateId: record.aggregateId,
                  version: record.version,
                  deletedAt: DateTime.now().toUtc(),
                )
              : null,
        );
        _store.putRoutine(applied);
        return SyncApplyOutcome.applied;
      case OutboxAggregateType.reminder:
        final local = _store.reminderById(ReminderId(record.aggregateId));
        if (local != null && !local.version.isBefore(record.version)) {
          return SyncApplyOutcome.skipped;
        }
        _store.putReminder(
          Reminder(
            id: ReminderId(record.aggregateId),
            familySpaceId: FamilySpaceId(record.familySpaceId),
            title: record.payload['title']! as String,
            scheduledAt: DateTime.parse(
              record.payload['scheduledAt']! as String,
            ),
            version: record.version,
            syncState: SyncState.synced,
            tombstone: record.tombstoned
                ? Tombstone(
                    aggregateId: record.aggregateId,
                    version: record.version,
                    deletedAt: DateTime.now().toUtc(),
                  )
                : null,
          ),
        );
        return SyncApplyOutcome.applied;
      case OutboxAggregateType.memory:
        final local = _store.memoryById(MemoryId(record.aggregateId));
        if (local != null && !local.version.isBefore(record.version)) {
          return SyncApplyOutcome.skipped;
        }
        _store.putMemory(
          MemoryEntry(
            id: MemoryId(record.aggregateId),
            familySpaceId: FamilySpaceId(record.familySpaceId),
            caption: record.payload['caption']! as String,
            dateContext: record.payload['dateContext']! as String,
            displayOrder: record.payload['displayOrder'] as int? ?? 0,
            lifecycleStatus: MemoryLifecycleStatus.parse(
              record.payload['lifecycle'] as String? ?? 'approved',
            ),
            version: record.version,
            syncState: SyncState.synced,
            tombstone: record.tombstoned
                ? Tombstone(
                    aggregateId: record.aggregateId,
                    version: record.version,
                    deletedAt: DateTime.now().toUtc(),
                  )
                : null,
          ),
        );
        return SyncApplyOutcome.applied;
      case OutboxAggregateType.pastime:
        final local = _store.pastimeById(PastimeId(record.aggregateId));
        if (local != null && !local.version.isBefore(record.version)) {
          return SyncApplyOutcome.skipped;
        }
        _store.putPastime(
          Pastime(
            id: PastimeId(record.aggregateId),
            familySpaceId: FamilySpaceId(record.familySpaceId),
            title: record.payload['title']! as String,
            instruction: record.payload['instruction']! as String,
            displayOrder: record.payload['displayOrder'] as int? ?? 0,
            lifecycleStatus: PastimeLifecycleStatus.parse(
              record.payload['lifecycle'] as String? ?? 'draft',
            ),
            version: record.version,
            syncState: SyncState.synced,
            tombstone: record.tombstoned
                ? Tombstone(
                    aggregateId: record.aggregateId,
                    version: record.version,
                    deletedAt: DateTime.now().toUtc(),
                  )
                : null,
          ),
        );
        return SyncApplyOutcome.applied;
      case OutboxAggregateType.conversationTopic:
        final local = _store.conversationTopicById(
          ConversationTopicId(record.aggregateId),
        );
        if (local != null && !local.version.isBefore(record.version)) {
          return SyncApplyOutcome.skipped;
        }
        _store.putConversationTopic(
          _topicFromPayload(
            aggregateId: record.aggregateId,
            familySpaceId: record.familySpaceId,
            payload: record.payload,
            version: record.version,
            tombstoned: record.tombstoned,
            syncState: SyncState.synced,
          ),
        );
        return SyncApplyOutcome.applied;
      case OutboxAggregateType.weightObservation:
        return _applyWeight(record, preserveBoth: preserveBoth);
      case OutboxAggregateType.bloodPressureObservation:
        return _applyBloodPressure(record, preserveBoth: preserveBoth);
      case OutboxAggregateType.routineProgress:
        return SyncApplyOutcome.skipped;
    }
  }

  Future<SyncApplyOutcome> _applyWeight(
    RemoteRecord record, {
    required bool preserveBoth,
  }) async {
    final existing = _store.weightById(ObservationId(record.aggregateId));
    if (existing != null) {
      if (preserveBoth) {
        // Append-only conflict: keep local row; remote body lives on SyncConflict.
        return SyncApplyOutcome.applied;
      }
      if (!existing.version.isBefore(record.version)) {
        return SyncApplyOutcome.skipped;
      }
    }
    _store.putWeight(
      WeightObservation(
        id: ObservationId(record.aggregateId),
        familySpaceId: FamilySpaceId(record.familySpaceId),
        kilograms: (record.payload['kilograms'] as num).toDouble(),
        recordedAt: DateTime.parse(record.payload['recordedAt']! as String),
        authorId: UserId(record.payload['authorId']! as String),
        version: record.version,
        syncState: SyncState.synced,
        tombstone: record.tombstoned
            ? Tombstone(
                aggregateId: record.aggregateId,
                version: record.version,
                deletedAt: DateTime.now().toUtc(),
              )
            : null,
      ),
    );
    return SyncApplyOutcome.applied;
  }

  Future<SyncApplyOutcome> _applyBloodPressure(
    RemoteRecord record, {
    required bool preserveBoth,
  }) async {
    final existing = _store.bloodPressureById(
      ObservationId(record.aggregateId),
    );
    if (existing != null) {
      if (preserveBoth) {
        return SyncApplyOutcome.applied;
      }
      if (!existing.version.isBefore(record.version)) {
        return SyncApplyOutcome.skipped;
      }
    }
    _store.putBloodPressure(
      BloodPressureObservation(
        id: ObservationId(record.aggregateId),
        familySpaceId: FamilySpaceId(record.familySpaceId),
        systolicMmHg: record.payload['systolic']! as int,
        diastolicMmHg: record.payload['diastolic']! as int,
        recordedAt: DateTime.parse(record.payload['recordedAt']! as String),
        authorId: UserId(record.payload['authorId']! as String),
        version: record.version,
        syncState: SyncState.synced,
        tombstone: record.tombstoned
            ? Tombstone(
                aggregateId: record.aggregateId,
                version: record.version,
                deletedAt: DateTime.now().toUtc(),
              )
            : null,
      ),
    );
    return SyncApplyOutcome.applied;
  }

  @override
  Future<void> applyConflictResolution(SyncConflict conflict) async {
    if (conflict.aggregateType == OutboxAggregateType.pastime) {
      await _applyPastimeConflictResolution(conflict);
      return;
    }
    if (conflict.aggregateType == OutboxAggregateType.conversationTopic) {
      await _applyConversationTopicConflictResolution(conflict);
      return;
    }
    if (conflict.aggregateType != OutboxAggregateType.routine) {
      return;
    }
    final payload = switch (conflict.resolution) {
      SyncConflictResolution.keepLocal => conflict.localPayload,
      SyncConflictResolution.keepRemote => conflict.remotePayload,
      SyncConflictResolution.keepBoth => conflict.localPayload,
      SyncConflictResolution.unresolved => null,
    };
    if (payload == null) {
      return;
    }
    final steps = (payload['steps'] as List<dynamic>? ?? const []).map((raw) {
      final map = Map<String, Object?>.from(raw as Map);
      return RoutineStep(
        order: map['order']! as int,
        instruction: map['instruction']! as String,
      );
    }).toList();
    final version = conflict.resolution == SyncConflictResolution.keepRemote
        ? conflict.remoteVersion
        : AggregateVersion(
            conflict.localVersion.value > conflict.remoteVersion.value
                ? conflict.localVersion.value
                : conflict.remoteVersion.value,
          );
    _store.putRoutine(
      Routine(
        id: RoutineId(conflict.aggregateId),
        familySpaceId: conflict.familySpaceId,
        title: payload['title']! as String,
        steps: steps.isEmpty
            ? [RoutineStep(order: 0, instruction: 'Paso Demo')]
            : steps,
        lifecycleStatus: RoutineLifecycleStatus.parse(
          payload['lifecycle'] as String? ?? 'active',
        ),
        version: version,
        syncState: SyncState.synced,
      ),
    );
    if (conflict.resolution == SyncConflictResolution.keepBoth) {
      final remoteSteps =
          (conflict.remotePayload['steps'] as List<dynamic>? ?? const []).map((
            raw,
          ) {
            final map = Map<String, Object?>.from(raw as Map);
            return RoutineStep(
              order: map['order']! as int,
              instruction: map['instruction']! as String,
            );
          }).toList();
      _store.putRoutine(
        Routine(
          id: RoutineId(_forkUuid(conflict.aggregateId)),
          familySpaceId: conflict.familySpaceId,
          title: conflict.remotePayload['title']! as String,
          steps: remoteSteps.isEmpty
              ? [RoutineStep(order: 0, instruction: 'Paso Demo')]
              : remoteSteps,
          lifecycleStatus: RoutineLifecycleStatus.parse(
            conflict.remotePayload['lifecycle'] as String? ?? 'active',
          ),
          version: conflict.remoteVersion,
          syncState: SyncState.synced,
        ),
      );
    }
  }

  Future<void> _applyPastimeConflictResolution(SyncConflict conflict) async {
    final payload = switch (conflict.resolution) {
      SyncConflictResolution.keepLocal => conflict.localPayload,
      SyncConflictResolution.keepRemote => conflict.remotePayload,
      SyncConflictResolution.keepBoth => conflict.localPayload,
      SyncConflictResolution.unresolved => null,
    };
    if (payload == null) {
      return;
    }
    final version = conflict.resolution == SyncConflictResolution.keepRemote
        ? conflict.remoteVersion
        : AggregateVersion(
            conflict.localVersion.value > conflict.remoteVersion.value
                ? conflict.localVersion.value
                : conflict.remoteVersion.value,
          );
    _store.putPastime(
      Pastime(
        id: PastimeId(conflict.aggregateId),
        familySpaceId: conflict.familySpaceId,
        title: payload['title']! as String,
        instruction: payload['instruction']! as String,
        displayOrder: payload['displayOrder'] as int? ?? 0,
        lifecycleStatus: PastimeLifecycleStatus.parse(
          payload['lifecycle'] as String? ?? 'draft',
        ),
        version: version,
        syncState: SyncState.synced,
      ),
    );
    if (conflict.resolution == SyncConflictResolution.keepBoth) {
      _store.putPastime(
        Pastime(
          id: PastimeId(_forkUuid(conflict.aggregateId)),
          familySpaceId: conflict.familySpaceId,
          title: conflict.remotePayload['title']! as String,
          instruction: conflict.remotePayload['instruction']! as String,
          displayOrder: conflict.remotePayload['displayOrder'] as int? ?? 0,
          lifecycleStatus: PastimeLifecycleStatus.parse(
            conflict.remotePayload['lifecycle'] as String? ?? 'draft',
          ),
          version: conflict.remoteVersion,
          syncState: SyncState.synced,
        ),
      );
    }
  }

  Future<void> _applyConversationTopicConflictResolution(
    SyncConflict conflict,
  ) async {
    final payload = switch (conflict.resolution) {
      SyncConflictResolution.keepLocal => conflict.localPayload,
      SyncConflictResolution.keepRemote => conflict.remotePayload,
      SyncConflictResolution.keepBoth => conflict.localPayload,
      SyncConflictResolution.unresolved => null,
    };
    if (payload == null) {
      return;
    }
    final version = conflict.resolution == SyncConflictResolution.keepRemote
        ? conflict.remoteVersion
        : AggregateVersion(
            conflict.localVersion.value > conflict.remoteVersion.value
                ? conflict.localVersion.value
                : conflict.remoteVersion.value,
          );
    _store.putConversationTopic(
      _topicFromPayload(
        aggregateId: conflict.aggregateId,
        familySpaceId: conflict.familySpaceId.value,
        payload: payload,
        version: version,
        tombstoned: false,
        syncState: SyncState.synced,
      ),
    );
    if (conflict.resolution == SyncConflictResolution.keepBoth) {
      _store.putConversationTopic(
        _topicFromPayload(
          aggregateId: _forkUuid(conflict.aggregateId),
          familySpaceId: conflict.familySpaceId.value,
          payload: conflict.remotePayload,
          version: conflict.remoteVersion,
          tombstoned: false,
          syncState: SyncState.synced,
        ),
      );
    }
  }

  static Map<String, Object?> _conversationTopicPayload(
    ConversationTopic topic,
  ) => ConversationTopicCodec.encodePayload(topic);

  static ConversationTopic _topicFromPayload({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) => ConversationTopicCodec.decodeTopic(
    aggregateId: aggregateId,
    familySpaceId: familySpaceId,
    payload: payload,
    version: version,
    tombstoned: tombstoned,
    syncState: syncState,
  );

  /// Deterministic valid UUID for a keep-both remote fork.
  static String _forkUuid(String aggregateId) {
    return '${aggregateId.substring(0, aggregateId.length - 2)}f1';
  }

  Future<void> _setSyncState(
    OutboxOperation operation,
    SyncState state, {
    AggregateVersion? version,
  }) async {
    switch (operation.aggregateType) {
      case OutboxAggregateType.routine:
        final current = _store.routineById(RoutineId(operation.aggregateId));
        if (current != null) {
          _store.putRoutine(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.reminder:
        final current = _store.reminderById(ReminderId(operation.aggregateId));
        if (current != null) {
          _store.putReminder(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.memory:
        final current = _store.memoryById(MemoryId(operation.aggregateId));
        if (current != null) {
          _store.putMemory(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.pastime:
        final current = _store.pastimeById(PastimeId(operation.aggregateId));
        if (current != null) {
          _store.putPastime(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.conversationTopic:
        final current = _store.conversationTopicById(
          ConversationTopicId(operation.aggregateId),
        );
        if (current != null) {
          _store.putConversationTopic(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.weightObservation:
        final current = _store.weightById(ObservationId(operation.aggregateId));
        if (current != null) {
          _store.putWeight(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.bloodPressureObservation:
        final current = _store.bloodPressureById(
          ObservationId(operation.aggregateId),
        );
        if (current != null) {
          _store.putBloodPressure(
            current.copyWith(syncState: state, version: version),
          );
        }
      case OutboxAggregateType.routineProgress:
        final current = _store.progressById(
          RoutineProgressId(operation.aggregateId),
        );
        if (current != null) {
          _store.putProgress(
            current.copyWith(syncState: state, version: version),
          );
        }
    }
  }
}
