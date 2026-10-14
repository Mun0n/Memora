import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../routines/unauthorized_care_action_exception.dart';
import 'audit_port.dart';
import 'audit_record.dart';

/// Family content types included when export/deletion contracts enumerate scope.
///
/// Caregiver-authored conversation topics are in scope. Ephemeral conversation
/// session surfaces (audio, transcripts, answers, durations, topic choice,
/// commands, history) are never included.
enum FamilyContentType {
  routines('routines'),
  reminders('reminders'),
  memories('memories'),
  pastimes('pastimes'),
  conversationTopics('conversationTopics'),
  weightObservations('weightObservations'),
  bloodPressureObservations('bloodPressureObservations');

  const FamilyContentType(this.wireName);

  final String wireName;
}

/// Normative export/deletion content scope for family-authored records.
abstract final class FamilyContentScope {
  static const List<FamilyContentType> exportAndDeletion = <FamilyContentType>[
    FamilyContentType.routines,
    FamilyContentType.reminders,
    FamilyContentType.memories,
    FamilyContentType.pastimes,
    FamilyContentType.conversationTopics,
    FamilyContentType.weightObservations,
    FamilyContentType.bloodPressureObservations,
  ];

  /// Surfaces that must never appear in persistence, outbox, sync, audit or
  /// export packages for guided conversations.
  ///
  /// Authored prompt help cards travel with [FamilyContentType.conversationTopics]
  /// as family content. Help *usage*, revealed-memory history and session speech
  /// remain excluded.
  static const Set<String> excludedConversationSessionSurfaces = <String>{
    'audio',
    'synthesizedAudio',
    'utteranceHistory',
    'speechOutputCache',
    'transcript',
    'recognizedText',
    'answerContent',
    'duration',
    'wordCount',
    'silence',
    'chosenTopic',
    'command',
    'conversationHistory',
    'participationScore',
    'completionEvent',
    'helpUseEvent',
    'helpRequestCount',
    'displayedMemoryHistory',
    'revealedHelpHistory',
    'helpTiming',
  };

  static bool includesConversationTopics() =>
      exportAndDeletion.contains(FamilyContentType.conversationTopics);
}

/// Export package request (contract only — no hosted delivery).
final class ExportPackageRequest {
  ExportPackageRequest({
    required this.id,
    required this.familySpaceId,
    required this.requestedBy,
    required this.requestedAt,
    required this.requestId,
    this.status = PrivacyRequestStatus.pending,
  });

  final String id;
  final FamilySpaceId familySpaceId;
  final UserId requestedBy;
  final DateTime requestedAt;
  final String requestId;
  final PrivacyRequestStatus status;
}

/// Deletion request (contract only — identity re-verify against host is later).
final class DeletionRequest {
  DeletionRequest({
    required this.id,
    required this.familySpaceId,
    required this.requestedBy,
    required this.requestedAt,
    required this.requestId,
    this.status = PrivacyRequestStatus.pending,
  });

  final String id;
  final FamilySpaceId familySpaceId;
  final UserId requestedBy;
  final DateTime requestedAt;
  final String requestId;
  final PrivacyRequestStatus status;
}

enum PrivacyRequestStatus { pending, confirmed, cancelled }

/// Session descriptor for list/revoke contracts (no tokens stored).
final class SessionDescriptor {
  SessionDescriptor({
    required this.id,
    required this.userId,
    required this.familySpaceId,
    required this.label,
    required this.createdAt,
    this.revokedAt,
  });

  final String id;
  final UserId userId;
  final FamilySpaceId familySpaceId;

  /// Human label only (e.g. `demo-tablet`); never a token.
  final String label;
  final DateTime createdAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;
}

abstract interface class PrivacyPort {
  Future<ExportPackageRequest> requestExport({
    required FamilyMembership actor,
    required String id,
    required String requestId,
    required DateTime requestedAt,
  });

  Future<DeletionRequest> requestDeletion({
    required FamilyMembership actor,
    required String id,
    required String requestId,
    required DateTime requestedAt,
  });

  Future<List<SessionDescriptor>> listSessions({
    required FamilyMembership actor,
  });

  Future<SessionDescriptor> revokeSession({
    required FamilyMembership actor,
    required String sessionId,
    required String requestId,
    required DateTime revokedAt,
  });
}

/// In-domain orchestration that records audit rows without sensitive payloads.
final class PrivacyWorkflow implements PrivacyPort {
  PrivacyWorkflow({required AuditPort audit, required PrivacyStore store})
    : _audit = audit,
      _store = store;

  final AuditPort _audit;
  final PrivacyStore _store;

  @override
  Future<ExportPackageRequest> requestExport({
    required FamilyMembership actor,
    required String id,
    required String requestId,
    required DateTime requestedAt,
  }) async {
    _assertActive(actor);
    final request = ExportPackageRequest(
      id: id,
      familySpaceId: actor.familySpaceId,
      requestedBy: actor.userId,
      requestedAt: requestedAt,
      requestId: requestId,
    );
    await _store.saveExport(request);
    await _audit.append(
      AuditRecord(
        id: 'audit-export-$id',
        familySpaceId: actor.familySpaceId,
        actorUserId: actor.userId,
        action: 'export.requested',
        targetType: 'export_package',
        targetId: id,
        occurredAt: requestedAt,
        requestId: requestId,
      ),
    );
    return request;
  }

  @override
  Future<DeletionRequest> requestDeletion({
    required FamilyMembership actor,
    required String id,
    required String requestId,
    required DateTime requestedAt,
  }) async {
    _assertActive(actor);
    final request = DeletionRequest(
      id: id,
      familySpaceId: actor.familySpaceId,
      requestedBy: actor.userId,
      requestedAt: requestedAt,
      requestId: requestId,
    );
    await _store.saveDeletion(request);
    await _audit.append(
      AuditRecord(
        id: 'audit-deletion-$id',
        familySpaceId: actor.familySpaceId,
        actorUserId: actor.userId,
        action: 'deletion.requested',
        targetType: 'deletion_request',
        targetId: id,
        occurredAt: requestedAt,
        requestId: requestId,
      ),
    );
    return request;
  }

  @override
  Future<List<SessionDescriptor>> listSessions({
    required FamilyMembership actor,
  }) async {
    _assertActive(actor);
    return _store.listSessions(actor.familySpaceId, actor.userId);
  }

  @override
  Future<SessionDescriptor> revokeSession({
    required FamilyMembership actor,
    required String sessionId,
    required String requestId,
    required DateTime revokedAt,
  }) async {
    _assertActive(actor);
    final session = await _store.revokeSession(
      familySpaceId: actor.familySpaceId,
      userId: actor.userId,
      sessionId: sessionId,
      revokedAt: revokedAt,
    );
    await _audit.append(
      AuditRecord(
        id: 'audit-session-$sessionId-$requestId',
        familySpaceId: actor.familySpaceId,
        actorUserId: actor.userId,
        action: 'session.revoked',
        targetType: 'session',
        targetId: sessionId,
        occurredAt: revokedAt,
        requestId: requestId,
      ),
    );
    return session;
  }

  void _assertActive(FamilyMembership actor) {
    if (!actor.isActive) {
      throw UnauthorizedCareActionException(
        'inactive membership cannot use privacy contracts',
      );
    }
  }
}

/// Persistence seam for privacy requests/sessions (implemented in data).
abstract interface class PrivacyStore {
  Future<void> saveExport(ExportPackageRequest request);

  Future<void> saveDeletion(DeletionRequest request);

  Future<List<SessionDescriptor>> listSessions(
    FamilySpaceId familySpaceId,
    UserId userId,
  );

  Future<SessionDescriptor> revokeSession({
    required FamilySpaceId familySpaceId,
    required UserId userId,
    required String sessionId,
    required DateTime revokedAt,
  });
}
