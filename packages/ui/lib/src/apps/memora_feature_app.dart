import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../experience_target.dart';
import '../family/family_memory_controller.dart';
import '../family/family_memory_page.dart';
import '../family/family_observation_controller.dart';
import '../family/family_observation_page.dart';
import '../family/family_routine_configure_page.dart';
import '../family/family_routine_controller.dart';
import '../help/help_about_page.dart';
import '../navigation/feature_section.dart';
import '../navigation/feature_section_nav.dart';
import '../theme/memora_theme.dart';
import '../user/user_approved_memories_page.dart';
import '../user/user_memory_controller.dart';
import '../user/user_routine_controller.dart';
import '../user/user_routine_home.dart';
import '../widgets/shell_scaffold.dart';

/// Supported-person app shell: routines, approved memories, Help/About.
class MemoraUserApp extends StatefulWidget {
  const MemoraUserApp({
    super.key,
    required this.controller,
    required this.persona,
    this.memoryController,
    this.autoload = true,
    this.initialSection = FeatureSection.routines,
  });

  final UserRoutineController controller;
  final UserMemoryController? memoryController;
  final SyntheticPersona persona;

  /// When true, triggers load after the first frame.
  final bool autoload;
  final FeatureSection initialSection;

  @override
  State<MemoraUserApp> createState() => _MemoraUserAppState();
}

class _MemoraUserAppState extends State<MemoraUserApp> {
  late FeatureSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
        widget.memoryController?.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora ${ExperienceTarget.user.englishLabel} (demo)',
      debugShowCheckedModeBanner: true,
      theme: MemoraTheme.light(),
      home: _UserShell(
        routineController: widget.controller,
        memoryController: widget.memoryController,
        persona: widget.persona,
        section: _section,
        onSection: (section) => setState(() => _section = section),
      ),
    );
  }
}

class _UserShell extends StatelessWidget {
  const _UserShell({
    required this.routineController,
    required this.memoryController,
    required this.persona,
    required this.section,
    required this.onSection,
  });

  final UserRoutineController routineController;
  final UserMemoryController? memoryController;
  final SyntheticPersona persona;
  final FeatureSection section;
  final ValueChanged<FeatureSection> onSection;

  @override
  Widget build(BuildContext context) {
    final sections = <FeatureSection>[
      FeatureSection.routines,
      if (memoryController != null) FeatureSection.memories,
      FeatureSection.help,
    ];
    final listenable = memoryController == null
        ? routineController
        : Listenable.merge(<Listenable>[routineController, memoryController!]);

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final syncLabel = switch (section) {
          FeatureSection.memories =>
            memoryController?.syncLabel ?? routineController.syncLabel,
          _ => routineController.syncLabel,
        };
        final syncAction = switch (section) {
          FeatureSection.memories => memoryController?.recoveryActionLabel,
          _ => routineController.recoveryActionLabel,
        };
        final onSync = syncAction == null
            ? null
            : () {
                if (section == FeatureSection.memories) {
                  memoryController?.recover();
                } else {
                  routineController.recover();
                }
              };

        return ShellScaffold(
          target: ExperienceTarget.user,
          persona: persona,
          syncLabel: syncLabel,
          syncActionLabel: syncAction,
          onSyncAction: onSync,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureSectionNav(
                sections: sections,
                selected: section,
                onSelected: onSection,
              ),
              const SizedBox(height: 20),
              switch (section) {
                FeatureSection.routines => UserRoutineHomeContent(
                  controller: routineController,
                ),
                FeatureSection.memories => UserApprovedMemoriesPage(
                  controller: memoryController!,
                ),
                FeatureSection.help => const HelpAboutPage(),
                FeatureSection.observations => const HelpAboutPage(),
              },
            ],
          ),
        );
      },
    );
  }
}

/// Caregiver/family web: routines, memories, observations, Help/About.
class MemoraFamilyWebApp extends StatefulWidget {
  const MemoraFamilyWebApp({
    super.key,
    required this.controller,
    required this.persona,
    this.memoryController,
    this.observationController,
    this.autoload = true,
    this.initialSection = FeatureSection.routines,
  });

  final FamilyRoutineController controller;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final SyntheticPersona persona;
  final bool autoload;
  final FeatureSection initialSection;

  @override
  State<MemoraFamilyWebApp> createState() => _MemoraFamilyWebAppState();
}

class _MemoraFamilyWebAppState extends State<MemoraFamilyWebApp> {
  late FeatureSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
        widget.memoryController?.load();
        widget.observationController?.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora ${ExperienceTarget.familyWeb.englishLabel} (demo)',
      debugShowCheckedModeBanner: true,
      theme: MemoraTheme.light(),
      home: _FamilyShell(
        routineController: widget.controller,
        memoryController: widget.memoryController,
        observationController: widget.observationController,
        persona: widget.persona,
        section: _section,
        onSection: (section) => setState(() => _section = section),
      ),
    );
  }
}

class _FamilyShell extends StatelessWidget {
  const _FamilyShell({
    required this.routineController,
    required this.memoryController,
    required this.observationController,
    required this.persona,
    required this.section,
    required this.onSection,
  });

  final FamilyRoutineController routineController;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final SyntheticPersona persona;
  final FeatureSection section;
  final ValueChanged<FeatureSection> onSection;

  @override
  Widget build(BuildContext context) {
    final sections = <FeatureSection>[
      FeatureSection.routines,
      if (memoryController != null) FeatureSection.memories,
      if (observationController != null) FeatureSection.observations,
      FeatureSection.help,
    ];
    final listenables = <Listenable>[routineController];
    if (memoryController != null) {
      listenables.add(memoryController!);
    }
    if (observationController != null) {
      listenables.add(observationController!);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final syncLabel = switch (section) {
          FeatureSection.memories =>
            memoryController?.syncLabel ?? routineController.syncLabel,
          FeatureSection.observations =>
            observationController?.syncLabel ?? routineController.syncLabel,
          _ => routineController.syncLabel,
        };
        final syncAction = switch (section) {
          FeatureSection.memories => memoryController?.recoveryActionLabel,
          FeatureSection.observations => null,
          _ => routineController.recoveryActionLabel,
        };
        final onSync = syncAction == null
            ? null
            : () {
                if (section == FeatureSection.memories) {
                  memoryController?.recover();
                } else {
                  routineController.recover();
                }
              };

        return ShellScaffold(
          target: ExperienceTarget.familyWeb,
          persona: persona,
          syncLabel: syncLabel,
          syncActionLabel: syncAction,
          onSyncAction: onSync,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureSectionNav(
                sections: sections,
                selected: section,
                onSelected: onSection,
              ),
              const SizedBox(height: 20),
              switch (section) {
                FeatureSection.routines => FamilyRoutineConfigureContent(
                  controller: routineController,
                ),
                FeatureSection.memories => FamilyMemoryPage(
                  controller: memoryController!,
                ),
                FeatureSection.observations => FamilyObservationPage(
                  controller: observationController!,
                ),
                FeatureSection.help => const HelpAboutPage(),
              },
            ],
          ),
        );
      },
    );
  }
}
