import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('export/deletion/session revoke append auditable history', () async {
    final audit = _MemoryAudit();
    final store = _MemoryPrivacyStore()
      ..seed(
        SessionDescriptor(
          id: '01932f00-0006-7000-8000-000000000680',
          userId: IdentityFixtures.elenaPrimaryUserId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          label: 'demo-tablet',
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      );
    final workflow = PrivacyWorkflow(audit: audit, store: store);
    final actor = IdentityFixtures.elenaPrimaryMembership;

    final export = await workflow.requestExport(
      actor: actor,
      id: '01932f00-0006-7000-8000-000000000681',
      requestId: 'req-export-demo-1',
      requestedAt: DateTime.utc(2026, 10, 10, 12),
    );
    expect(export.status, PrivacyRequestStatus.pending);

    final deletion = await workflow.requestDeletion(
      actor: actor,
      id: '01932f00-0006-7000-8000-000000000682',
      requestId: 'req-deletion-demo-1',
      requestedAt: DateTime.utc(2026, 10, 10, 12, 1),
    );
    expect(deletion.familySpaceId, actor.familySpaceId);

    final sessions = await workflow.listSessions(actor: actor);
    expect(sessions, hasLength(1));

    final revoked = await workflow.revokeSession(
      actor: actor,
      sessionId: sessions.single.id,
      requestId: 'req-session-demo-1',
      revokedAt: DateTime.utc(2026, 10, 10, 12, 2),
    );
    expect(revoked.isActive, isFalse);

    final history = await audit.listForFamily(actor.familySpaceId);
    expect(history.map((e) => e.action).toList(), [
      'export.requested',
      'deletion.requested',
      'session.revoked',
    ]);
    for (final row in history) {
      expect(row.requestId, isNotEmpty);
      expect(row.targetId, isNotEmpty);
    }
  });

  test('inactive membership cannot use privacy contracts', () async {
    final workflow = PrivacyWorkflow(
      audit: _MemoryAudit(),
      store: _MemoryPrivacyStore(),
    );
    expect(
      () => workflow.requestExport(
        actor: IdentityFixtures.revokedContributorMembership,
        id: '01932f00-0006-7000-8000-000000000683',
        requestId: 'req-x',
        requestedAt: DateTime.utc(2026, 10, 10),
      ),
      throwsA(isA<UnauthorizedCareActionException>()),
    );
  });
}

final class _MemoryAudit implements AuditPort {
  final List<AuditRecord> rows = <AuditRecord>[];

  @override
  Future<void> append(AuditRecord record) async => rows.add(record);

  @override
  Future<List<AuditRecord>> listForFamily(FamilySpaceId familySpaceId) async =>
      rows.where((r) => r.familySpaceId == familySpaceId).toList();
}

final class _MemoryPrivacyStore implements PrivacyStore {
  final Map<String, SessionDescriptor> sessions = <String, SessionDescriptor>{};

  void seed(SessionDescriptor session) => sessions[session.id] = session;

  @override
  Future<void> saveExport(ExportPackageRequest request) async {}

  @override
  Future<void> saveDeletion(DeletionRequest request) async {}

  @override
  Future<List<SessionDescriptor>> listSessions(
    FamilySpaceId familySpaceId,
    UserId userId,
  ) async => sessions.values
      .where((s) => s.familySpaceId == familySpaceId && s.userId == userId)
      .toList();

  @override
  Future<SessionDescriptor> revokeSession({
    required FamilySpaceId familySpaceId,
    required UserId userId,
    required String sessionId,
    required DateTime revokedAt,
  }) async {
    final current = sessions[sessionId]!;
    final revoked = SessionDescriptor(
      id: current.id,
      userId: current.userId,
      familySpaceId: current.familySpaceId,
      label: current.label,
      createdAt: current.createdAt,
      revokedAt: revokedAt,
    );
    sessions[sessionId] = revoked;
    return revoked;
  }
}
