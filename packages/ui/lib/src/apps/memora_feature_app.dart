import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../experience_target.dart';
import '../family/family_memory_controller.dart';
import '../family/family_memory_page.dart';
import '../family/family_observation_controller.dart';
import '../family/family_observation_page.dart';
import '../family/family_pastime_configure_page.dart';
import '../family/family_pastime_controller.dart';
import '../family/family_routine_configure_page.dart';
import '../family/family_routine_controller.dart';
import '../help/help_about_page.dart';
import '../navigation/feature_section.dart';
import '../navigation/feature_section_nav.dart';
import '../privacy/privacy_page.dart';
import '../privacy/privacy_presentation_controller.dart';
import '../sync/sync_presentation_controller.dart';
import '../sync/sync_status_page.dart';
import '../theme/memora_theme.dart';
import '../user/user_approved_memories_page.dart';
import '../user/user_destination_scaffold.dart';
import '../user/user_home_destination.dart';
import '../user/user_home_grid.dart';
import '../user/user_memory_controller.dart';
import '../user/user_pastime_controller.dart';
import '../user/user_pastimes_page.dart';
import '../user/user_placeholder_page.dart';
import '../user/user_routine_controller.dart';
import '../user/user_routine_home.dart';
import '../user/user_voice_guidance_controller.dart';
import '../user/user_voice_guidance_panel.dart';
import '../widgets/shell_scaffold.dart';

/// Supported-person app shell: four-tile home and calm destinations.
///
/// Sync/privacy controllers may still load behind the presentation; they are
/// never exposed as home navigation or chrome.
class MemoraUserApp extends StatefulWidget {
  const MemoraUserApp({
    super.key,
    required this.controller,
    required this.persona,
    this.memoryController,
    this.pastimeController,
    this.syncController,
    this.privacyController,
    this.speechRecognizer,
    this.autoload = true,
    this.initialDestination = UserHomeDestination.home,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.enableQuietRemotePull = false,
  });

  final UserRoutineController controller;
  final UserMemoryController? memoryController;
  final UserPastimeController? pastimeController;
  final SyncPresentationController? syncController;
  final PrivacyPresentationController? privacyController;

  /// Tap-gated speech port. Defaults to [FakeSpeechRecognizer] (no real mic).
  final SpeechRecognizerPort? speechRecognizer;
  final SyntheticPersona persona;

  /// When true, triggers load after the first frame.
  final bool autoload;
  final UserHomeDestination initialDestination;
  final DemoDataScope demoDataScope;

  /// Quiet pull on startup/resume when shared local demo transport is wired.
  final bool enableQuietRemotePull;

  @override
  State<MemoraUserApp> createState() => _MemoraUserAppState();
}

class _MemoraUserAppState extends State<MemoraUserApp>
    with WidgetsBindingObserver {
  late UserHomeDestination _destination;
  late final SpeechRecognizerPort _speechRecognizer;
  late final UserVoiceGuidanceController _voiceGuidance;

  /// Monotonic token so overlapping quiet pulls never apply stale refreshes.
  var _quietPullGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _destination = widget.initialDestination;
    _speechRecognizer = widget.speechRecognizer ?? FakeSpeechRecognizer();
    _voiceGuidance = UserVoiceGuidanceController(
      recognizer: _speechRecognizer,
      contentSnapshot: _buildVoiceContentSnapshot,
    );
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.controller.load();
        await widget.memoryController?.load();
        await widget.pastimeController?.load();
        // Background sync/privacy contracts — not shown on home.
        await widget.syncController?.load();
        await widget.privacyController?.load();
        await _quietPullPastimes();
      });
    } else if (widget.enableQuietRemotePull) {
      // Real executable: main() already called composition.load(); still pull.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quietPullPastimes();
      });
    }
  }

  VoiceContentSnapshot _buildVoiceContentSnapshot() {
    return VoiceContentSnapshot(
      hasCurrentOrPendingMiDia: widget.controller.hasCurrentOrPendingMiDiaStep,
      hasActivePastimes: widget.pastimeController?.pastimes.isNotEmpty ?? false,
      hasApprovedMemories:
          widget.memoryController?.memories.isNotEmpty ?? false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceGuidance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _quietPullPastimes();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Spec: release microphone on lifecycle pause / navigation away.
      _voiceGuidance.releaseForLifecycle();
    }
  }

  Future<void> _quietPullPastimes() async {
    if (!widget.enableQuietRemotePull) {
      return;
    }
    final generation = ++_quietPullGeneration;
    final pastime = widget.pastimeController;
    if (pastime == null) {
      return;
    }
    // Pull + refresh via controller so shared failures surface retry chrome.
    await pastime.refreshFromSharedRemote();
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
  }

  void _goHome() {
    _voiceGuidance.releaseForLifecycle();
    setState(() => _destination = UserHomeDestination.home);
  }

  void _open(UserHomeDestination destination) {
    _voiceGuidance.releaseForLifecycle();
    setState(() => _destination = destination);
    if (destination == UserHomeDestination.pasatiempos) {
      // Cached cards already painted; quiet pull refreshes without trapping nav.
      _quietPullPastimes();
    }
  }

  Future<void> _confirmVoiceNavigate() async {
    final target = await _voiceGuidance.confirmNavigate();
    if (target != null && mounted) {
      _open(target);
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
        pastimeController: widget.pastimeController,
        voiceGuidance: _voiceGuidance,
        destination: _destination,
        onOpen: _open,
        onReturnHome: _goHome,
        onAyudame: _voiceGuidance.startFromExplicitTap,
        onConfirmVoiceNavigate: _confirmVoiceNavigate,
      ),
    );
  }
}

class _UserShell extends StatelessWidget {
  const _UserShell({
    required this.routineController,
    required this.memoryController,
    required this.pastimeController,
    required this.voiceGuidance,
    required this.destination,
    required this.onOpen,
    required this.onReturnHome,
    required this.onAyudame,
    required this.onConfirmVoiceNavigate,
  });

  final UserRoutineController routineController;
  final UserMemoryController? memoryController;
  final UserPastimeController? pastimeController;
  final UserVoiceGuidanceController voiceGuidance;
  final UserHomeDestination destination;
  final ValueChanged<UserHomeDestination> onOpen;
  final VoidCallback onReturnHome;
  final VoidCallback onAyudame;
  final VoidCallback onConfirmVoiceNavigate;

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[routineController, voiceGuidance];
    if (memoryController != null) {
      listenables.add(memoryController!);
    }
    if (pastimeController != null) {
      listenables.add(pastimeController!);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        if (destination == UserHomeDestination.home) {
          return Scaffold(
            backgroundColor: MemoraTheme.highContrastSurface,
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.sizeOf(context).width >=
                              MemoraTheme.expandedBreakpoint
                          ? 40
                          : 24,
                      vertical:
                          MediaQuery.sizeOf(context).width >=
                              MemoraTheme.expandedBreakpoint
                          ? 28
                          : 20,
                    ),
                    child: UserHomeGrid(
                      orientationLabel: routineController.orientationLabel,
                      onSelect: onOpen,
                      onAyudame: onAyudame,
                    ),
                  ),
                ),
                if (voiceGuidance.isActive)
                  Positioned.fill(
                    child: UserVoiceGuidancePanel(
                      controller: voiceGuidance,
                      onConfirmNavigate: onConfirmVoiceNavigate,
                    ),
                  ),
              ],
            ),
          );
        }

        final scrollable =
            destination == UserHomeDestination.recuerdos ||
            destination == UserHomeDestination.pasatiempos;
        return UserDestinationScaffold(
          onReturnHome: onReturnHome,
          scrollable: scrollable,
          body: switch (destination) {
            UserHomeDestination.home => const SizedBox.shrink(),
            UserHomeDestination.miDia => UserMiDiaContent(
              controller: routineController,
            ),
            UserHomeDestination.pasatiempos =>
              pastimeController == null
                  ? UserPlaceholderPage.pasatiempos()
                  : UserPastimesPage(controller: pastimeController!),
            UserHomeDestination.quieroHablar =>
              UserPlaceholderPage.quieroHablar(),
            UserHomeDestination.recuerdos =>
              memoryController == null
                  ? const SizedBox.shrink()
                  : UserApprovedMemoriesPage(controller: memoryController!),
          },
        );
      },
    );
  }
}

/// Caregiver/family web: routines, pastimes, memories, observations, sync,
/// privacy, Help.
class MemoraFamilyWebApp extends StatefulWidget {
  const MemoraFamilyWebApp({
    super.key,
    required this.controller,
    required this.persona,
    this.pastimeController,
    this.memoryController,
    this.observationController,
    this.syncController,
    this.privacyController,
    this.autoload = true,
    this.initialSection = FeatureSection.routines,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.enableQuietRemotePull = false,
  });

  final FamilyRoutineController controller;
  final FamilyPastimeController? pastimeController;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final SyncPresentationController? syncController;
  final PrivacyPresentationController? privacyController;
  final SyntheticPersona persona;
  final bool autoload;
  final FeatureSection initialSection;
  final DemoDataScope demoDataScope;

  /// Quiet pull when entering Pasatiempos in shared local demo mode.
  final bool enableQuietRemotePull;

  @override
  State<MemoraFamilyWebApp> createState() => _MemoraFamilyWebAppState();
}

class _MemoraFamilyWebAppState extends State<MemoraFamilyWebApp> {
  late FeatureSection _section;

  /// Monotonic token so overlapping quiet pulls never apply stale refreshes.
  var _quietPullGeneration = 0;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.controller.load();
        await widget.pastimeController?.load();
        await widget.memoryController?.load();
        await widget.observationController?.load();
        await widget.syncController?.load();
        await widget.privacyController?.load();
        if (_section == FeatureSection.pastimes) {
          await _quietPullPastimes();
        }
      });
    } else if (widget.enableQuietRemotePull &&
        _section == FeatureSection.pastimes) {
      // Real executable: main() already called composition.load(); still pull.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quietPullPastimes();
      });
    }
  }

  Future<void> _quietPullPastimes() async {
    if (!widget.enableQuietRemotePull) {
      return;
    }
    final generation = ++_quietPullGeneration;
    final pastime = widget.pastimeController;
    if (pastime == null) {
      return;
    }
    await pastime.refreshFromSharedRemote();
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
  }

  void _selectSection(FeatureSection section) {
    setState(() => _section = section);
    if (section == FeatureSection.pastimes) {
      _quietPullPastimes();
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
        pastimeController: widget.pastimeController,
        memoryController: widget.memoryController,
        observationController: widget.observationController,
        syncController: widget.syncController,
        privacyController: widget.privacyController,
        persona: widget.persona,
        section: _section,
        onSection: _selectSection,
        demoDataScope: widget.demoDataScope,
      ),
    );
  }
}

class _FamilyShell extends StatelessWidget {
  const _FamilyShell({
    required this.routineController,
    required this.pastimeController,
    required this.memoryController,
    required this.observationController,
    required this.syncController,
    required this.privacyController,
    required this.persona,
    required this.section,
    required this.onSection,
    required this.demoDataScope,
  });

  final FamilyRoutineController routineController;
  final FamilyPastimeController? pastimeController;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final SyncPresentationController? syncController;
  final PrivacyPresentationController? privacyController;
  final SyntheticPersona persona;
  final FeatureSection section;
  final ValueChanged<FeatureSection> onSection;
  final DemoDataScope demoDataScope;

  @override
  Widget build(BuildContext context) {
    final sections = <FeatureSection>[
      FeatureSection.routines,
      if (pastimeController != null) FeatureSection.pastimes,
      if (memoryController != null) FeatureSection.memories,
      if (observationController != null) FeatureSection.observations,
      if (syncController != null) FeatureSection.sync,
      if (privacyController != null) FeatureSection.privacy,
      FeatureSection.help,
    ];
    final listenables = <Listenable>[routineController];
    if (pastimeController != null) {
      listenables.add(pastimeController!);
    }
    if (memoryController != null) {
      listenables.add(memoryController!);
    }
    if (observationController != null) {
      listenables.add(observationController!);
    }
    if (syncController != null) {
      listenables.add(syncController!);
    }
    if (privacyController != null) {
      listenables.add(privacyController!);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final syncLabel = switch (section) {
          FeatureSection.sync =>
            syncController?.syncChromeLabel ?? routineController.syncLabel,
          FeatureSection.pastimes =>
            pastimeController?.syncLabel ?? routineController.syncLabel,
          FeatureSection.memories =>
            memoryController?.syncLabel ?? routineController.syncLabel,
          FeatureSection.observations =>
            observationController?.syncLabel ?? routineController.syncLabel,
          FeatureSection.privacy =>
            syncController?.sessionLabel ?? routineController.syncLabel,
          _ =>
            syncController?.unresolved.isNotEmpty == true
                ? syncController!.syncChromeLabel
                : routineController.syncLabel,
        };
        final syncAction = switch (section) {
          FeatureSection.sync => syncController?.recoveryActionLabel,
          FeatureSection.pastimes => pastimeController?.recoveryActionLabel,
          FeatureSection.memories => memoryController?.recoveryActionLabel,
          FeatureSection.observations => null,
          FeatureSection.privacy => null,
          _ =>
            syncController?.unresolved.isNotEmpty == true
                ? syncController!.recoveryActionLabel
                : routineController.recoveryActionLabel,
        };
        final onSync = syncAction == null
            ? null
            : () {
                if (section == FeatureSection.sync ||
                    syncController?.unresolved.isNotEmpty == true) {
                  syncController?.recover();
                } else if (section == FeatureSection.pastimes) {
                  pastimeController?.recover();
                } else if (section == FeatureSection.memories) {
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
                FeatureSection.pastimes => FamilyPastimeConfigureContent(
                  controller: pastimeController!,
                ),
                FeatureSection.memories => FamilyMemoryPage(
                  controller: memoryController!,
                ),
                FeatureSection.observations => FamilyObservationPage(
                  controller: observationController!,
                ),
                FeatureSection.sync => SyncStatusPage(
                  controller: syncController!,
                  demoDataScope: demoDataScope,
                ),
                FeatureSection.privacy => PrivacyPage(
                  controller: privacyController!,
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
