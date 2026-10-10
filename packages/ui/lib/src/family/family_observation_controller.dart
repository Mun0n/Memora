import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Caregiver observation controller over [RecordObservations].
///
/// Storage-only UX — no thresholds, severity colors or advice.
final class FamilyObservationController extends ChangeNotifier {
  FamilyObservationController({
    required this.actor,
    required WeightObservationRepository weights,
    required BloodPressureObservationRepository bloodPressures,
    this.networkAvailable = false,
    DateTime? clock,
    DemoIds? ids,
    RecordObservations? recordObservations,
  }) : _clock = clock,
       _ids = ids ?? DemoIds(),
       _record =
           recordObservations ??
           RecordObservations(weights: weights, bloodPressures: bloodPressures);

  final FamilyMembership actor;
  final RecordObservations _record;
  final DemoIds _ids;
  final DateTime? _clock;

  bool networkAvailable;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<WeightObservation> weights = const <WeightObservation>[];
  List<BloodPressureObservation> bloodPressures =
      const <BloodPressureObservation>[];
  String? errorMessage;

  String draftWeightKg = '';
  String draftSystolic = '';
  String draftDiastolic = '';
  ObservationId? correctingWeightId;
  ObservationId? correctingBpId;
  int editorRevision = 0;

  bool get canRecord => ObservationCarePolicy.canRecordObservations(actor);

  DateTime get now => _clock ?? DateTime.now();

  String get syncLabel {
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.observationsLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return MemoraCopy.observationsEmpty;
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.stateOffline;
    }
    return MemoraCopy.syncLocal;
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    errorMessage = null;
    notifyListeners();
    if (!canRecord) {
      weights = const <WeightObservation>[];
      bloodPressures = const <BloodPressureObservation>[];
      surfaceState = PresentationSurfaceState.empty;
      errorMessage = 'No tienes permiso para registrar observaciones.';
      notifyListeners();
      return;
    }
    try {
      weights = await _record.listWeightHistory(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      bloodPressures = await _record.listBloodPressureHistory(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      surfaceState = weights.isEmpty && bloodPressures.isEmpty
          ? PresentationSurfaceState.empty
          : (!networkAvailable
                ? PresentationSurfaceState.offline
                : PresentationSurfaceState.ready);
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  void setDraftWeightKg(String value) => draftWeightKg = value;

  void setDraftSystolic(String value) => draftSystolic = value;

  void setDraftDiastolic(String value) => draftDiastolic = value;

  void beginCorrectWeight(ObservationId id) {
    correctingWeightId = id;
    draftWeightKg = '';
    editorRevision += 1;
    notifyListeners();
  }

  void beginCorrectBloodPressure(ObservationId id) {
    correctingBpId = id;
    draftSystolic = '';
    draftDiastolic = '';
    editorRevision += 1;
    notifyListeners();
  }

  Future<void> saveWeight() async {
    if (!canRecord) {
      errorMessage = 'No tienes permiso para registrar observaciones.';
      notifyListeners();
      return;
    }
    final kg = double.tryParse(draftWeightKg.trim().replaceAll(',', '.'));
    if (kg == null || kg <= 0) {
      errorMessage = 'Introduce un peso válido en kg.';
      notifyListeners();
      return;
    }
    try {
      if (correctingWeightId == null) {
        await _record.addWeight(
          actor: actor,
          id: _ids.nextObservationId(),
          familySpaceId: actor.familySpaceId,
          kilograms: kg,
          recordedAt: now.toUtc(),
          idempotencyKey: _ids.nextIdempotencyKey('weight-add'),
        );
      } else {
        await _record.correctWeight(
          actor: actor,
          sourceId: correctingWeightId!,
          correctionId: _ids.nextObservationId(),
          kilograms: kg,
          recordedAt: now.toUtc(),
          idempotencyKey: _ids.nextIdempotencyKey('weight-correct'),
        );
      }
      draftWeightKg = '';
      correctingWeightId = null;
      editorRevision += 1;
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> saveBloodPressure() async {
    if (!canRecord) {
      errorMessage = 'No tienes permiso para registrar observaciones.';
      notifyListeners();
      return;
    }
    final sys = int.tryParse(draftSystolic.trim());
    final dia = int.tryParse(draftDiastolic.trim());
    if (sys == null || dia == null || sys <= 0 || dia <= 0) {
      errorMessage = 'Introduce valores de tensión válidos en mmHg.';
      notifyListeners();
      return;
    }
    try {
      if (correctingBpId == null) {
        await _record.addBloodPressure(
          actor: actor,
          id: _ids.nextObservationId(),
          familySpaceId: actor.familySpaceId,
          systolicMmHg: sys,
          diastolicMmHg: dia,
          recordedAt: now.toUtc(),
          idempotencyKey: _ids.nextIdempotencyKey('bp-add'),
        );
      } else {
        await _record.correctBloodPressure(
          actor: actor,
          sourceId: correctingBpId!,
          correctionId: _ids.nextObservationId(),
          systolicMmHg: sys,
          diastolicMmHg: dia,
          recordedAt: now.toUtc(),
          idempotencyKey: _ids.nextIdempotencyKey('bp-correct'),
        );
      }
      draftSystolic = '';
      draftDiastolic = '';
      correctingBpId = null;
      editorRevision += 1;
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> tombstoneWeight(WeightObservation observation) async {
    try {
      await _record.tombstoneWeight(
        actor: actor,
        id: observation.id,
        baseVersion: observation.version,
        deletedAt: now.toUtc(),
        idempotencyKey: _ids.nextIdempotencyKey('weight-tombstone'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> tombstoneBloodPressure(
    BloodPressureObservation observation,
  ) async {
    try {
      await _record.tombstoneBloodPressure(
        actor: actor,
        id: observation.id,
        baseVersion: observation.version,
        deletedAt: now.toUtc(),
        idempotencyKey: _ids.nextIdempotencyKey('bp-tombstone'),
      );
      await load();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}
