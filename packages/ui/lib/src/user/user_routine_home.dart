import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../experience_target.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/shell_scaffold.dart';
import 'user_routine_controller.dart';

/// Supported-person home: orientation, today's routines, one primary action.
class UserRoutineHome extends StatelessWidget {
  const UserRoutineHome({
    super.key,
    required this.controller,
    required this.persona,
  });

  final UserRoutineController controller;
  final SyntheticPersona persona;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ShellScaffold(
          target: ExperienceTarget.user,
          persona: persona,
          syncLabel: controller.syncLabel,
          syncActionLabel: controller.recoveryActionLabel,
          onSyncAction: controller.recoveryActionLabel == null
              ? null
              : () => controller.recover(),
          body: UserRoutineHomeContent(controller: controller),
        );
      },
    );
  }
}

/// Routine home body without chrome (used inside the Slice 5 section shell).
class UserRoutineHomeContent extends StatelessWidget {
  const UserRoutineHomeContent({super.key, required this.controller});

  final UserRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = controller.primaryAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.userHomeTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            controller.orientationLabel,
            key: const Key('memora-user-orientation'),
            style: textTheme.titleLarge?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          MemoraCopy.todaysRoutines,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (controller.routines.isEmpty)
          Text(
            MemoraCopy.stateEmpty,
            key: const Key('memora-user-empty'),
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          )
        else
          ...controller.routines.map((routine) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoutineSummary(routine: routine, controller: controller),
            );
          }),
        const SizedBox(height: 16),
        Text(
          MemoraCopy.nextStepLabel,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (action == null)
          Text(
            MemoraCopy.noPrimaryAction,
            key: const Key('memora-user-no-action'),
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          )
        else ...[
          Text(
            '${action.routine.title}: ${action.step.instruction}',
            key: const Key('memora-user-primary-step'),
            style: textTheme.titleLarge?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('memora-user-primary-action'),
            onPressed: () => controller.togglePrimaryAction(),
            child: Text(
              action.isCompleted
                  ? MemoraCopy.primaryActionCorrect
                  : MemoraCopy.primaryActionComplete,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoutineSummary extends StatelessWidget {
  const _RoutineSummary({required this.routine, required this.controller});

  final Routine routine;
  final UserRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: routine.title,
      child: DecoratedBox(
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
                routine.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              ...routine.steps.map((step) {
                final status = controller.statusFor(routine, step);
                final label = status == StepCompletionStatus.completed
                    ? MemoraCopy.stepCompleted
                    : MemoraCopy.stepPending;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${step.order + 1}. ${step.instruction} ($label)',
                    style: textTheme.bodyLarge?.copyWith(fontSize: 18),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
