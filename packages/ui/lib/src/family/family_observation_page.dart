import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/spanish_date_format.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_observation_controller.dart';

/// Caregiver observation entry + chronological history with disclaimer.
///
/// No severity colors, thresholds or medical advice copy.
class FamilyObservationPage extends StatelessWidget {
  const FamilyObservationPage({super.key, required this.controller});

  final FamilyObservationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.observationsTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              MemoraCopy.observationDisclaimer,
              key: const Key('memora-observation-disclaimer'),
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (!controller.canRecord)
              Text(
                controller.errorMessage ??
                    'No tienes permiso para registrar observaciones.',
                key: const Key('memora-observation-denied'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              )
            else ...[
              Text(
                MemoraCopy.weightSection,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DraftTextField(
                key: const Key('memora-weight-kg'),
                revision: controller.editorRevision,
                initialText: controller.draftWeightKg,
                onChanged: controller.setDraftWeightKg,
                labelText: MemoraCopy.weightValueLabel,
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('memora-save-weight'),
                onPressed: controller.saveWeight,
                child: Text(
                  controller.correctingWeightId == null
                      ? MemoraCopy.saveWeight
                      : MemoraCopy.correctObservation,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                MemoraCopy.bloodPressureSection,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DraftTextField(
                key: const Key('memora-bp-systolic'),
                revision: controller.editorRevision,
                initialText: controller.draftSystolic,
                onChanged: controller.setDraftSystolic,
                labelText: MemoraCopy.systolicLabel,
              ),
              const SizedBox(height: 8),
              DraftTextField(
                key: const Key('memora-bp-diastolic'),
                revision: controller.editorRevision,
                initialText: controller.draftDiastolic,
                onChanged: controller.setDraftDiastolic,
                labelText: MemoraCopy.diastolicLabel,
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('memora-save-bp'),
                onPressed: controller.saveBloodPressure,
                child: Text(
                  controller.correctingBpId == null
                      ? MemoraCopy.saveBloodPressure
                      : MemoraCopy.correctObservation,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                MemoraCopy.observationHistory,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (controller.weights.isEmpty &&
                  controller.bloodPressures.isEmpty)
                Text(
                  MemoraCopy.observationsEmpty,
                  key: const Key('memora-observations-empty'),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                )
              else ...[
                ...controller.weights.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _WeightRow(observation: row, controller: controller),
                  ),
                ),
                ...controller.bloodPressures.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BpRow(observation: row, controller: controller),
                  ),
                ),
              ],
            ],
            if (controller.errorMessage != null && controller.canRecord) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                key: const Key('memora-observation-error'),
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.observation, required this.controller});

  final WeightObservation observation;
  final FamilyObservationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stamp = SpanishDateFormat.formatDateTime(
      observation.recordedAt.toLocal(),
    );
    final correction = observation.isCorrection
        ? ' · ${MemoraCopy.observationCorrectionOf} '
              '${observation.correctsObservationId!.value}'
        : '';
    final tombstoned = observation.isDeleted
        ? ' · ${MemoraCopy.observationTombstoned}'
        : '';
    return DecoratedBox(
      key: Key('memora-weight-row-${observation.id.value}'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${observation.kilograms} ${WeightObservation.unitLabel} · $stamp'
              '$correction$tombstoned',
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            Text(
              '${MemoraCopy.observationAuthorLabel}: '
              '${observation.authorId.value}',
              style: textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
            if (!observation.isDeleted) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: Key('memora-weight-correct-${observation.id.value}'),
                    onPressed: () =>
                        controller.beginCorrectWeight(observation.id),
                    child: const Text(MemoraCopy.correctObservation),
                  ),
                  OutlinedButton(
                    key: Key('memora-weight-tombstone-${observation.id.value}'),
                    onPressed: () => controller.tombstoneWeight(observation),
                    child: const Text(MemoraCopy.tombstoneObservation),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BpRow extends StatelessWidget {
  const _BpRow({required this.observation, required this.controller});

  final BloodPressureObservation observation;
  final FamilyObservationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stamp = SpanishDateFormat.formatDateTime(
      observation.recordedAt.toLocal(),
    );
    final correction = observation.isCorrection
        ? ' · ${MemoraCopy.observationCorrectionOf} '
              '${observation.correctsObservationId!.value}'
        : '';
    final tombstoned = observation.isDeleted
        ? ' · ${MemoraCopy.observationTombstoned}'
        : '';
    return DecoratedBox(
      key: Key('memora-bp-row-${observation.id.value}'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${observation.systolicMmHg}/'
              '${observation.diastolicMmHg} '
              '${BloodPressureObservation.unitLabel} · $stamp'
              '$correction$tombstoned',
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            Text(
              '${MemoraCopy.observationAuthorLabel}: '
              '${observation.authorId.value}',
              style: textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
            if (!observation.isDeleted) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: Key('memora-bp-correct-${observation.id.value}'),
                    onPressed: () =>
                        controller.beginCorrectBloodPressure(observation.id),
                    child: const Text(MemoraCopy.correctObservation),
                  ),
                  OutlinedButton(
                    key: Key('memora-bp-tombstone-${observation.id.value}'),
                    onPressed: () =>
                        controller.tombstoneBloodPressure(observation),
                    child: const Text(MemoraCopy.tombstoneObservation),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
