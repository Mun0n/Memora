import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';

/// Presentation controller over domain [PrivacyPort] contracts.
final class PrivacyPresentationController extends ChangeNotifier {
  PrivacyPresentationController({
    required this.actor,
    required PrivacyPort privacy,
    this.sessionBoundary = SessionBoundary.demo,
    DemoIds? ids,
    DateTime? clock,
  }) : _privacy = privacy,
       _ids = ids ?? DemoIds(start: 0x900),
       _clock = clock;

  final FamilyMembership actor;
  final PrivacyPort _privacy;
  final SessionBoundary sessionBoundary;
  final DemoIds _ids;
  final DateTime? _clock;

  bool busy = false;
  String? statusMessage;
  String? errorMessage;
  List<SessionDescriptor> sessions = const <SessionDescriptor>[];
  ExportPackageRequest? lastExport;
  DeletionRequest? lastDeletion;

  DateTime get _now => _clock ?? DateTime.now().toUtc();

  Future<void> load() async {
    errorMessage = null;
    try {
      sessions = await _privacy.listSessions(actor: actor);
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.privacyUnauthorized;
      sessions = const <SessionDescriptor>[];
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> requestExport() async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final id = _ids.nextUuid();
      lastExport = await _privacy.requestExport(
        actor: actor,
        id: id,
        requestId: 'req-export-$id',
        requestedAt: _now,
      );
      statusMessage = MemoraCopy.privacyExportConfirmed;
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.privacyUnauthorized;
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> requestDeletion() async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final id = _ids.nextUuid();
      lastDeletion = await _privacy.requestDeletion(
        actor: actor,
        id: id,
        requestId: 'req-deletion-$id',
        requestedAt: _now,
      );
      statusMessage = MemoraCopy.privacyDeletionConfirmed;
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.privacyUnauthorized;
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> revokeSession(String sessionId) async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final requestId = 'req-session-${_ids.nextUuid()}';
      await _privacy.revokeSession(
        actor: actor,
        sessionId: sessionId,
        requestId: requestId,
        revokedAt: _now,
      );
      statusMessage = MemoraCopy.privacySessionRevoked;
      sessions = await _privacy.listSessions(actor: actor);
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.privacyUnauthorized;
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }
}
