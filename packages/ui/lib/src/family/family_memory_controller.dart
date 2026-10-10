import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Caregiver/family memory controller over [ManageMemory].
///
/// UI visibility uses [MemoryCarePolicy]; domain remains authoritative.
final class FamilyMemoryController extends ChangeNotifier {
  FamilyMemoryController({
    required this.actor,
    required MemoryRepository memories,
    this.networkAvailable = false,
    DemoIds? ids,
    ManageMemory? manageMemory,
  }) : _memories = memories,
       _ids = ids ?? DemoIds(),
       _manage = manageMemory ?? ManageMemory(memories);

  final FamilyMembership actor;
  final MemoryRepository _memories;
  final ManageMemory _manage;
  final DemoIds _ids;

  bool networkAvailable;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<MemoryEntry> memories = const <MemoryEntry>[];
  String? errorMessage;

  MemoryId? editingMemoryId;
  String draftCaption = '';
  String draftDateContext = '';
  int editorRevision = 0;

  bool get canManage => MemoryCarePolicy.canManageMemories(actor);
  bool get canContribute => MemoryCarePolicy.canContributeMemories(actor);

  String get syncLabel {
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.memoriesLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.memoriesEmpty
          : '${MemoraCopy.memoriesEmpty} ${MemoraCopy.memoriesOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (surfaceState == PresentationSurfaceState.conflicted) {
      return MemoraCopy.syncConflicted;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.memoriesOffline;
    }
    return SyncStatusLabels.forSyncState(_worstSync());
  }

  String? get recoveryActionLabel {
    return switch (surfaceState) {
      PresentationSurfaceState.failed => MemoraCopy.recoveryRetry,
      PresentationSurfaceState.conflicted => MemoraCopy.recoveryReviewConflict,
      PresentationSurfaceState.offline => MemoraCopy.recoveryContinueOffline,
      PresentationSurfaceState.empty =>
        canManage || canContribute
            ? (canManage
                  ? MemoraCopy.createMemory
                  : MemoraCopy.contributeMemory)
            : null,
      PresentationSurfaceState.loading => null,
      PresentationSurfaceState.ready =>
        !networkAvailable ? MemoraCopy.recoveryContinueOffline : null,
    };
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final listed = await _memories.listForFamily(actor.familySpaceId);
      memories = listed.where((m) => !m.isDeleted).toList(growable: false)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      surfaceState = _deriveSurface(memories);
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  Future<void> recover() async {
    if (surfaceState == PresentationSurfaceState.empty) {
      beginCreate();
      return;
    }
    if (surfaceState == PresentationSurfaceState.offline ||
        (!networkAvailable && surfaceState == PresentationSurfaceState.ready)) {
      surfaceState = memories.isEmpty
          ? PresentationSurfaceState.empty
          : PresentationSurfaceState.ready;
      notifyListeners();
      return;
    }
    await load();
  }

  void beginCreate() {
    editingMemoryId = null;
    draftCaption = '';
    draftDateContext = '';
    editorRevision += 1;
    notifyListeners();
  }

  void beginEdit(MemoryEntry memory) {
    editingMemoryId = memory.id;
    draftCaption = memory.caption;
    draftDateContext = memory.dateContext;
    editorRevision += 1;
    notifyListeners();
  }

  void setDraftCaption(String value) => draftCaption = value;

  void setDraftDateContext(String value) => draftDateContext = value;

  Future<void> saveDraft() async {
    if (draftCaption.trim().isEmpty || draftDateContext.trim().isEmpty) {
      errorMessage = 'Pie de foto y contexto de fecha son obligatorios.';
      notifyListeners();
      return;
    }
    try {
      if (editingMemoryId == null) {
        if (canManage) {
          await _manage.create(
            actor: actor,
            id: _ids.nextMemoryId(),
            familySpaceId: actor.familySpaceId,
            caption: draftCaption.trim(),
            dateContext: draftDateContext.trim(),
            displayOrder: memories.length,
            idempotencyKey: _ids.nextIdempotencyKey('memory-create'),
          );
        } else if (canContribute) {
          await _manage.contribute(
            actor: actor,
            id: _ids.nextMemoryId(),
            familySpaceId: actor.familySpaceId,
            caption: draftCaption.trim(),
            dateContext: draftDateContext.trim(),
            displayOrder: memories.length,
            idempotencyKey: _ids.nextIdempotencyKey('memory-contribute'),
          );
        } else {
          errorMessage = 'No tienes permiso para añadir recuerdos.';
          notifyListeners();
          return;
        }
      } else {
        await _manage.edit(
          actor: actor,
          id: editingMemoryId!,
          caption: draftCaption.trim(),
          dateContext: draftDateContext.trim(),
          idempotencyKey: _ids.nextIdempotencyKey('memory-edit'),
        );
      }
      editingMemoryId = null;
      draftCaption = '';
      draftDateContext = '';
      editorRevision += 1;
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> approve(MemoryId id) async {
    try {
      await _manage.approve(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('memory-approve'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> archive(MemoryId id) async {
    try {
      await _manage.archive(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('memory-archive'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> move(MemoryEntry memory, int delta) async {
    final target = memory.displayOrder + delta;
    if (target < 0) {
      return;
    }
    try {
      await _manage.reorder(
        actor: actor,
        id: memory.id,
        displayOrder: target,
        idempotencyKey: _ids.nextIdempotencyKey('memory-reorder'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> retryMedia(MemoryId id) async {
    try {
      await _manage.retryFailedMedia(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('memory-retry-media'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  PresentationSurfaceState _deriveSurface(List<MemoryEntry> listed) {
    if (listed.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(listed.map((m) => m.syncState));
    if (worst == SyncState.conflicted) {
      return PresentationSurfaceState.conflicted;
    }
    if (worst == SyncState.failed) {
      return PresentationSurfaceState.failed;
    }
    if (!networkAvailable) {
      return PresentationSurfaceState.offline;
    }
    return PresentationSurfaceState.ready;
  }

  SyncState _worstSync() {
    if (memories.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(memories.map((m) => m.syncState));
  }
}
