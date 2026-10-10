import 'package:domain/domain.dart';

/// Local privacy request/session store for demo mode (no hosted delivery).
final class InMemoryPrivacyStore implements PrivacyStore {
  final Map<String, ExportPackageRequest> _exports =
      <String, ExportPackageRequest>{};
  final Map<String, DeletionRequest> _deletions = <String, DeletionRequest>{};
  final Map<String, SessionDescriptor> _sessions =
      <String, SessionDescriptor>{};

  void seedSession(SessionDescriptor session) {
    _sessions[session.id] = session;
  }

  @override
  Future<void> saveExport(ExportPackageRequest request) async {
    _exports[request.id] = request;
  }

  @override
  Future<void> saveDeletion(DeletionRequest request) async {
    _deletions[request.id] = request;
  }

  @override
  Future<List<SessionDescriptor>> listSessions(
    FamilySpaceId familySpaceId,
    UserId userId,
  ) async {
    return _sessions.values
        .where((s) => s.familySpaceId == familySpaceId && s.userId == userId)
        .toList(growable: false);
  }

  @override
  Future<SessionDescriptor> revokeSession({
    required FamilySpaceId familySpaceId,
    required UserId userId,
    required String sessionId,
    required DateTime revokedAt,
  }) async {
    final current = _sessions[sessionId];
    if (current == null ||
        current.familySpaceId != familySpaceId ||
        current.userId != userId) {
      throw StateError('unknown session: $sessionId');
    }
    final revoked = SessionDescriptor(
      id: current.id,
      userId: current.userId,
      familySpaceId: current.familySpaceId,
      label: current.label,
      createdAt: current.createdAt,
      revokedAt: revokedAt,
    );
    _sessions[sessionId] = revoked;
    return revoked;
  }
}
