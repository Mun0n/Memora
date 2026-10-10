import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'routine_step.dart';

/// Daily/care routine with ordered steps. Local-first aggregate.
final class Routine {
  Routine({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required List<RoutineStep> steps,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) : steps = List<RoutineStep>.unmodifiable(_validateSteps(steps)) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must be non-empty');
    }
  }

  final RoutineId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final List<RoutineStep> steps;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  Routine copyWith({
    String? title,
    List<RoutineStep>? steps,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return Routine(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      steps: steps ?? this.steps,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }

  static List<RoutineStep> _validateSteps(List<RoutineStep> steps) {
    if (steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'must contain at least one step',
      );
    }
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].order != i) {
        throw ArgumentError.value(
          steps.map((s) => s.order).toList(),
          'steps.order',
          'must be contiguous from 0',
        );
      }
    }
    return sorted;
  }
}
