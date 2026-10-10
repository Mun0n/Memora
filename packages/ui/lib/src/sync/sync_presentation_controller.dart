import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../l10n/memora_copy.dart';
import 'presentation_sync.dart';

/// Presentation controller over domain [SyncEngine] + conflict store.
///
/// Does not import data adapters; apps compose the fake remote.
final class SyncPresentationController extends ChangeNotifier {
  SyncPresentationController({
    required this.actor,
    required SyncEngine engine,
    required ConflictStorePort conflicts,
    this.sessionBoundary = SessionBoundary.demo,
  }) : _engine = engine,
       _conflicts = conflicts;

  final FamilyMembership actor;
  final SyncEngine _engine;
  final ConflictStorePort _conflicts;
  final SessionBoundary sessionBoundary;

  bool busy = false;
  String? errorMessage;
  SyncPushSummary? lastPush;
  SyncPullSummary? lastPull;
  List<SyncConflict> unresolved = const <SyncConflict>[];

  bool get canResolveConflicts =>
      RoutineCarePolicy.canResolveSyncConflicts(actor);

  String get sessionLabel {
    return switch (sessionBoundary.mode) {
      SessionCompositionMode.demoOffline => MemoraCopy.sessionDemoTitle,
      SessionCompositionMode.signedOut => MemoraCopy.sessionSignedOutTitle,
      SessionCompositionMode.namedCredentialsConfigured =>
        MemoraCopy.sessionNamedCredentialsTitle,
    };
  }

  String get syncChromeLabel {
    if (busy) {
      return MemoraCopy.syncBusy;
    }
    if (unresolved.isNotEmpty) {
      return MemoraCopy.syncConflicted;
    }
    if (lastPush != null && lastPush!.failed > 0) {
      return MemoraCopy.syncFailed;
    }
    if (lastPush != null && lastPush!.applied + lastPush!.duplicates > 0) {
      return MemoraCopy.syncSynced;
    }
    if (!sessionBoundary.requiresNetwork) {
      return MemoraCopy.stateOffline;
    }
    return MemoraCopy.syncPending;
  }

  String? get recoveryActionLabel {
    if (busy) {
      return null;
    }
    if (unresolved.isNotEmpty) {
      return MemoraCopy.recoveryReviewConflict;
    }
    if (lastPush != null && lastPush!.failed > 0) {
      return MemoraCopy.recoveryRetry;
    }
    return MemoraCopy.syncPushAction;
  }

  Future<void> load() async {
    errorMessage = null;
    unresolved = await _conflicts.listUnresolved(actor.familySpaceId);
    notifyListeners();
  }

  Future<void> push() async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      lastPush = await _engine.pushPending();
      unresolved = await _conflicts.listUnresolved(actor.familySpaceId);
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> pull() async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      lastPull = await _engine.pull(familySpaceId: actor.familySpaceId);
      unresolved = await _conflicts.listUnresolved(actor.familySpaceId);
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> recover() async {
    if (unresolved.isNotEmpty) {
      await load();
      return;
    }
    await push();
  }

  Future<void> resolve({
    required String conflictId,
    required SyncConflictResolution resolution,
  }) async {
    if (busy) {
      return;
    }
    if (!canResolveConflicts) {
      errorMessage = MemoraCopy.syncResolveUnauthorized;
      notifyListeners();
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _engine.resolveConflict(
        actor: actor,
        conflictId: conflictId,
        resolution: resolution,
      );
      unresolved = await _conflicts.listUnresolved(actor.familySpaceId);
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.syncResolveUnauthorized;
    } catch (error) {
      errorMessage = error.toString();
    }
    busy = false;
    notifyListeners();
  }

  /// Safe label for conflict chrome — never surfaces health values or media URLs.
  static String conflictKindLabel(SyncConflict conflict) {
    return switch (conflict.aggregateType) {
      OutboxAggregateType.routine => MemoraCopy.syncConflictRoutine,
      OutboxAggregateType.weightObservation ||
      OutboxAggregateType.bloodPressureObservation =>
        MemoraCopy.syncConflictObservation,
      _ => MemoraCopy.syncConflictOther,
    };
  }

  static String conflictSummary(SyncConflict conflict) {
    final kind = conflictKindLabel(conflict);
    // Titles only for routines; never dump observation kilograms/BP payloads.
    if (conflict.aggregateType == OutboxAggregateType.routine) {
      final localTitle = conflict.localPayload['title'];
      final remoteTitle = conflict.remotePayload['title'];
      if (localTitle is String && remoteTitle is String) {
        return '$kind · local: $localTitle · remota: $remoteTitle';
      }
    }
    return '$kind · id ${conflict.aggregateId}';
  }

  static String pushSummaryLabel(SyncPushSummary summary) {
    return '${MemoraCopy.syncPushSummaryPrefix}'
        ' aplicados ${summary.applied},'
        ' duplicados ${summary.duplicates},'
        ' conflictos ${summary.conflicted},'
        ' fallidos ${summary.failed}';
  }

  static String pullSummaryLabel(SyncPullSummary summary) {
    return '${MemoraCopy.syncPullSummaryPrefix}'
        ' aplicados ${summary.applied},'
        ' omitidos ${summary.skipped}';
  }

  /// Worst aggregate sync across optional feature lists for status chrome.
  static SyncState worstOf(Iterable<SyncState> states) {
    return SyncStatusLabels.worstOf(states);
  }
}
