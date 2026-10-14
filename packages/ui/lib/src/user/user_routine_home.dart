import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';
import 'user_routine_controller.dart';

/// Supported-person "Mi día": one current/next step and one primary action.
class UserMiDiaPage extends StatelessWidget {
  const UserMiDiaPage({super.key, required this.controller});

  final UserRoutineController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => UserMiDiaContent(controller: controller),
    );
  }
}

/// Mi día body without destination chrome.
class UserMiDiaContent extends StatelessWidget {
  const UserMiDiaContent({super.key, required this.controller});

  final UserRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = controller.primaryAction;

    return Column(
      key: const Key('memora-user-mi-dia'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.miDiaTitle,
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
            key: const Key('memora-user-mi-dia-orientation'),
            style: textTheme.titleMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.body,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          MemoraCopy.nextStepLabel,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: MemoraSupportedPersonTypography.secondary,
          ),
        ),
        const SizedBox(height: 12),
        if (action == null)
          Text(
            MemoraCopy.miDiaEmptyBody,
            key: const Key('memora-user-no-action'),
            style: textTheme.bodyLarge?.copyWith(
              fontSize: MemoraSupportedPersonTypography.body,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          )
        else ...[
          Text(
            action.step.instruction,
            key: const Key('memora-user-primary-step'),
            style: textTheme.titleLarge?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.title,
              fontWeight: FontWeight.w600,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.routine.title,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: MemoraSupportedPersonTypography.secondary,
              height: MemoraSupportedPersonTypography.bodyHeight,
              color: MemoraTheme.highContrastInk,
            ),
          ),
          const SizedBox(height: 20),
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

/// Backward-compatible name for Mi día body (Slice 6 call sites).
class UserRoutineHomeContent extends StatelessWidget {
  const UserRoutineHomeContent({super.key, required this.controller});

  final UserRoutineController controller;

  @override
  Widget build(BuildContext context) {
    return UserMiDiaContent(controller: controller);
  }
}

/// Standalone Mi día surface without the four-tile shell (tests / embeds).
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.supportedPerson(),
      home: Scaffold(
        backgroundColor: MemoraTheme.highContrastSurface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              label: persona.displayName,
              child: UserMiDiaPage(controller: controller),
            ),
          ),
        ),
      ),
    );
  }
}
