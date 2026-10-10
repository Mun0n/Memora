import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../experience_target.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import '../widgets/shell_scaffold.dart';
import 'family_routine_controller.dart';

/// Caregiver/family web: create/edit/order/activate/archive + quiet-hours reminders.
class FamilyRoutineConfigurePage extends StatelessWidget {
  const FamilyRoutineConfigurePage({
    super.key,
    required this.controller,
    required this.persona,
  });

  final FamilyRoutineController controller;
  final SyntheticPersona persona;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ShellScaffold(
          target: ExperienceTarget.familyWeb,
          persona: persona,
          syncLabel: controller.syncLabel,
          syncActionLabel: controller.recoveryActionLabel,
          onSyncAction: controller.recoveryActionLabel == null
              ? null
              : () => controller.recover(),
          body: FamilyRoutineConfigureContent(controller: controller),
        );
      },
    );
  }
}

/// Routine/reminder configure body without chrome (Slice 5 section shell).
class FamilyRoutineConfigureContent extends StatelessWidget {
  const FamilyRoutineConfigureContent({super.key, required this.controller});

  final FamilyRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.familyHomeTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          MemoraCopy.reminderConvenienceNotice,
          key: const Key('memora-reminder-convenience-notice'),
          style: textTheme.bodyLarge?.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 20),
        Text(
          MemoraCopy.routinesSection,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...controller.routines.map(
          (routine) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoutineCard(routine: routine, controller: controller),
          ),
        ),
        if (controller.routines.isEmpty)
          Text(
            MemoraCopy.stateEmpty,
            key: const Key('memora-family-empty'),
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('memora-family-begin-create'),
          onPressed: controller.beginCreateRoutine,
          child: const Text(MemoraCopy.createRoutine),
        ),
        const SizedBox(height: 20),
        _RoutineEditor(controller: controller),
        const SizedBox(height: 28),
        Text(
          MemoraCopy.remindersSection,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...controller.reminders.map(
          (reminder) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReminderCard(reminder: reminder, controller: controller),
          ),
        ),
        OutlinedButton(
          key: const Key('memora-family-begin-reminder'),
          onPressed: controller.beginCreateReminder,
          child: const Text(MemoraCopy.createReminder),
        ),
        const SizedBox(height: 16),
        _ReminderEditor(controller: controller),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            controller.errorMessage!,
            key: const Key('memora-family-error'),
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.controller});

  final Routine routine;
  final FamilyRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lifecycle = routine.lifecycleStatus == RoutineLifecycleStatus.active
        ? MemoraCopy.lifecycleActive
        : MemoraCopy.lifecycleArchived;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${routine.title} ($lifecycle)',
              key: Key('memora-family-routine-${routine.id.value}'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            ...routine.steps.map(
              (step) => Text(
                '${step.order + 1}. ${step.instruction}',
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('memora-family-edit-${routine.id.value}'),
                  onPressed: () => controller.beginEditRoutine(routine),
                  child: const Text(MemoraCopy.editRoutine),
                ),
                if (routine.lifecycleStatus == RoutineLifecycleStatus.archived)
                  FilledButton(
                    key: Key('memora-family-activate-${routine.id.value}'),
                    onPressed: () => controller.activate(routine.id),
                    child: const Text(MemoraCopy.activateRoutine),
                  )
                else
                  OutlinedButton(
                    key: Key('memora-family-archive-${routine.id.value}'),
                    onPressed: () => controller.archive(routine.id),
                    child: const Text(MemoraCopy.archiveRoutine),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineEditor extends StatelessWidget {
  const _RoutineEditor({required this.controller});

  final FamilyRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = controller.editingRoutineId != null;
    return DecoratedBox(
      key: const Key('memora-family-routine-editor'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? MemoraCopy.editRoutine : MemoraCopy.createRoutine,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            DraftTextField(
              key: const Key('memora-family-routine-title'),
              revision:
                  '${controller.editingRoutineId?.value ?? 'new'}-${controller.draftSteps.length}',
              initialText: controller.draftTitle,
              labelText: MemoraCopy.routineTitleLabel,
              onChanged: controller.setDraftTitle,
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(controller.draftSteps.length, (index) {
              final instruction = controller.draftSteps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DraftTextField(
                      key: Key('memora-family-step-$index'),
                      revision:
                          '${controller.editingRoutineId?.value ?? 'new'}-step-$index-${controller.draftSteps.length}',
                      initialText: instruction,
                      labelText:
                          '${MemoraCopy.stepInstructionLabel} ${index + 1}',
                      onChanged: (value) =>
                          controller.setDraftStep(index, value),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          key: Key('memora-family-step-up-$index'),
                          onPressed: () => controller.moveDraftStep(index, -1),
                          child: const Text(MemoraCopy.moveStepUp),
                        ),
                        OutlinedButton(
                          key: Key('memora-family-step-down-$index'),
                          onPressed: () => controller.moveDraftStep(index, 1),
                          child: const Text(MemoraCopy.moveStepDown),
                        ),
                        OutlinedButton(
                          key: Key('memora-family-step-remove-$index'),
                          onPressed: () => controller.removeDraftStep(index),
                          child: const Text(MemoraCopy.removeStep),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            OutlinedButton(
              key: const Key('memora-family-add-step'),
              onPressed: controller.addDraftStep,
              child: const Text(MemoraCopy.addStep),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('memora-family-save-routine'),
              onPressed: () => controller.saveDraftRoutine(),
              child: const Text(MemoraCopy.saveRoutine),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.controller});

  final Reminder reminder;
  final FamilyRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quiet = reminder.quietHours;
    final quietLabel = quiet == null
        ? 'Sin horas de silencio'
        : '${MemoraCopy.quietHoursLabel}: '
              '${(quiet.startMinuteOfDay ~/ 60).toString().padLeft(2, '0')}:00–'
              '${(quiet.endMinuteOfDay ~/ 60).toString().padLeft(2, '0')}:00';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.title,
              key: Key('memora-family-reminder-${reminder.id.value}'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quietLabel,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: Key('memora-family-edit-reminder-${reminder.id.value}'),
              onPressed: () => controller.beginEditReminder(reminder),
              child: const Text(MemoraCopy.editReminder),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditor extends StatelessWidget {
  const _ReminderEditor({required this.controller});

  final FamilyRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const Key('memora-family-reminder-editor'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.createReminder,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              MemoraCopy.quietHoursHint,
              style: textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            DraftTextField(
              key: const Key('memora-family-reminder-title'),
              revision: controller.editingReminderId?.value ?? 'new-reminder',
              initialText: controller.draftReminderTitle,
              labelText: MemoraCopy.reminderTitleLabel,
              onChanged: controller.setDraftReminderTitle,
            ),
            const SizedBox(height: 12),
            Text(
              '${MemoraCopy.quietStartLabel}: ${controller.quietStartHour}:00',
              style: textTheme.bodyLarge,
            ),
            Slider(
              key: const Key('memora-family-quiet-start'),
              value: controller.quietStartHour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: '${controller.quietStartHour}:00',
              onChanged: (value) => controller.setQuietStartHour(value.round()),
            ),
            Text(
              '${MemoraCopy.quietEndLabel}: ${controller.quietEndHour}:00',
              style: textTheme.bodyLarge,
            ),
            Slider(
              key: const Key('memora-family-quiet-end'),
              value: controller.quietEndHour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: '${controller.quietEndHour}:00',
              onChanged: (value) => controller.setQuietEndHour(value.round()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('memora-family-save-reminder'),
              onPressed: () => controller.saveDraftReminder(),
              child: const Text(MemoraCopy.saveReminder),
            ),
          ],
        ),
      ),
    );
  }
}
