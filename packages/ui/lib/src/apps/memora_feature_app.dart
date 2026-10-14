import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../experience_target.dart';
import '../family/family_memory_controller.dart';
import '../family/family_memory_page.dart';
import '../family/family_observation_controller.dart';
import '../family/family_observation_page.dart';
import '../family/family_conversation_topic_configure_page.dart';
import '../family/family_conversation_topic_controller.dart';
import '../family/family_pastime_configure_page.dart';
import '../family/family_pastime_controller.dart';
import '../family/family_routine_configure_page.dart';
import '../family/family_routine_controller.dart';
import '../family/family_supported_person_profile_controller.dart';
import '../family/family_supported_person_profile_page.dart';
import '../help/help_about_page.dart';
import '../l10n/memora_copy.dart';
import '../navigation/feature_section.dart';
import '../navigation/feature_section_nav.dart';
import '../privacy/privacy_page.dart';
import '../privacy/privacy_presentation_controller.dart';
import '../sync/sync_presentation_controller.dart';
import '../sync/sync_status_page.dart';
import '../theme/memora_theme.dart';
import '../user/user_approved_memories_page.dart';
import '../user/user_conversation_session_controller.dart';
import '../user/user_conversation_topic_controller.dart';
import '../user/user_conversation_topics_page.dart';
import '../user/user_destination_scaffold.dart';
import '../user/user_home_destination.dart';
import '../user/user_home_grid.dart';
import '../user/user_memory_controller.dart';
import '../user/user_pastime_controller.dart';
import '../user/user_pastimes_page.dart';
import '../user/user_placeholder_page.dart';
import '../user/user_routine_controller.dart';
import '../user/user_routine_home.dart';
import '../user/user_supported_person_profile_controller.dart';
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
    this.conversationTopicController,
    this.supportedPersonProfileController,
    this.syncController,
    this.privacyController,
    this.speechRecognizer,
    this.speechOutput,
    this.autoload = true,
    this.initialDestination = UserHomeDestination.home,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.enableQuietRemotePull = false,
    this.enableLiveOrientation = false,
  });

  final UserRoutineController controller;
  final UserMemoryController? memoryController;
  final UserPastimeController? pastimeController;
  final UserConversationTopicController? conversationTopicController;
  final UserSupportedPersonProfileController? supportedPersonProfileController;
  final SyncPresentationController? syncController;
  final PrivacyPresentationController? privacyController;

  /// Tap-gated speech port. Defaults to [FakeSpeechRecognizer] (no real mic).
  final SpeechRecognizerPort? speechRecognizer;

  /// Local speech-output port. Defaults to [FakeSpeechOutput] (no real TTS).
  final SpeechOutputPort? speechOutput;
  final SyntheticPersona persona;

  /// When true, triggers load after the first frame.
  final bool autoload;
  final UserHomeDestination initialDestination;
  final DemoDataScope demoDataScope;

  /// Quiet pull on startup/resume when shared local demo transport is wired.
  final bool enableQuietRemotePull;

  /// Minute/midnight/resume orientation refresh (executable demo only).
  ///
  /// Off by default so widget tests never hang on [pumpAndSettle] timers.
  final bool enableLiveOrientation;

  @override
  State<MemoraUserApp> createState() => _MemoraUserAppState();
}

class _MemoraUserAppState extends State<MemoraUserApp>
    with WidgetsBindingObserver {
  late UserHomeDestination _destination;
  late final SpeechRecognizerPort _speechRecognizer;
  late final SpeechOutputPort _speechOutput;
  late final UserVoiceGuidanceController _voiceGuidance;
  late final UserConversationSessionController _conversationSession;
  Timer? _orientationTimer;

  /// Monotonic token so overlapping quiet pulls never apply stale refreshes.
  var _quietPullGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _destination = widget.initialDestination;
    _speechRecognizer = widget.speechRecognizer ?? FakeSpeechRecognizer();
    _speechOutput = widget.speechOutput ?? FakeSpeechOutput();
    _voiceGuidance = UserVoiceGuidanceController(
      recognizer: _speechRecognizer,
      contentSnapshot: _buildVoiceContentSnapshot,
    );
    _conversationSession = UserConversationSessionController(
      recognizer: _speechRecognizer,
      speechOutput: _speechOutput,
      approvedMemoryLookup: () =>
          widget.memoryController?.memories ?? const <MemoryEntry>[],
    );
    if (widget.enableLiveOrientation && widget.controller.usesLiveClock) {
      _scheduleOrientationTick();
    }
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.controller.load();
        await widget.memoryController?.load();
        await widget.pastimeController?.load();
        await widget.conversationTopicController?.load();
        await widget.supportedPersonProfileController?.load();
        // Background sync/privacy contracts — not shown on home.
        await widget.syncController?.load();
        await widget.privacyController?.load();
        await _quietPullFamilyContent();
      });
    } else if (widget.enableQuietRemotePull) {
      // Real executable: main() already called composition.load(); still pull.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quietPullFamilyContent();
      });
    }
  }

  void _scheduleOrientationTick() {
    _orientationTimer?.cancel();
    if (!widget.enableLiveOrientation || !widget.controller.usesLiveClock) {
      return;
    }
    final now = widget.controller.now;
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    var delay = nextMinute.difference(now);
    if (delay.isNegative || delay == Duration.zero) {
      delay = const Duration(seconds: 1);
    }
    _orientationTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      // Presentation-only: does not recreate repos, sync, nav or speech.
      widget.controller.refreshOrientation();
      _scheduleOrientationTick();
    });
  }

  VoiceContentSnapshot _buildVoiceContentSnapshot() {
    return VoiceContentSnapshot(
      hasCurrentOrPendingMiDia: widget.controller.hasCurrentOrPendingMiDiaStep,
      hasActivePastimes: widget.pastimeController?.pastimes.isNotEmpty ?? false,
      hasApprovedMemories:
          widget.memoryController?.memories.isNotEmpty ?? false,
      hasActiveConversationTopics:
          widget.conversationTopicController?.hasActiveTopics ?? false,
    );
  }

  @override
  void dispose() {
    _orientationTimer?.cancel();
    _orientationTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _voiceGuidance.dispose();
    _conversationSession.releaseForLifecycle();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.enableLiveOrientation && widget.controller.usesLiveClock) {
        widget.controller.refreshOrientation();
        _scheduleOrientationTick();
      }
      _quietPullFamilyContent();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Spec: release microphone on lifecycle pause / navigation away.
      _voiceGuidance.releaseForLifecycle();
      _conversationSession.releaseForLifecycle();
    }
  }

  Future<void> _quietPullFamilyContent() async {
    if (!widget.enableQuietRemotePull) {
      return;
    }
    final generation = ++_quietPullGeneration;
    final pastime = widget.pastimeController;
    final topics = widget.conversationTopicController;
    final profile = widget.supportedPersonProfileController;
    if (pastime != null) {
      await pastime.refreshFromSharedRemote();
    }
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
    if (topics != null) {
      await topics.refreshFromSharedRemote();
    }
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
    if (profile != null) {
      await profile.refreshFromSharedRemote();
    }
  }

  void _goHome() {
    _voiceGuidance.releaseForLifecycle();
    _conversationSession.releaseForLifecycle();
    setState(() => _destination = UserHomeDestination.home);
  }

  void _open(UserHomeDestination destination) {
    _voiceGuidance.releaseForLifecycle();
    if (destination != UserHomeDestination.quieroHablar) {
      _conversationSession.releaseForLifecycle();
    }
    setState(() => _destination = destination);
    if (destination == UserHomeDestination.pasatiempos ||
        destination == UserHomeDestination.quieroHablar) {
      // Cached cards already painted; quiet pull refreshes without trapping nav.
      _quietPullFamilyContent();
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
        conversationTopicController: widget.conversationTopicController,
        supportedPersonProfileController:
            widget.supportedPersonProfileController,
        conversationSession: _conversationSession,
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
    required this.conversationTopicController,
    required this.supportedPersonProfileController,
    required this.conversationSession,
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
  final UserConversationTopicController? conversationTopicController;
  final UserSupportedPersonProfileController? supportedPersonProfileController;
  final UserConversationSessionController conversationSession;
  final UserVoiceGuidanceController voiceGuidance;
  final UserHomeDestination destination;
  final ValueChanged<UserHomeDestination> onOpen;
  final VoidCallback onReturnHome;
  final VoidCallback onAyudame;
  final VoidCallback onConfirmVoiceNavigate;

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      routineController,
      voiceGuidance,
      conversationSession,
    ];
    if (memoryController != null) {
      listenables.add(memoryController!);
    }
    if (pastimeController != null) {
      listenables.add(pastimeController!);
    }
    if (conversationTopicController != null) {
      listenables.add(conversationTopicController!);
    }
    if (supportedPersonProfileController != null) {
      listenables.add(supportedPersonProfileController!);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        if (destination == UserHomeDestination.home) {
          final greeting =
              supportedPersonProfileController?.homeGreeting ??
              MemoraCopy.userHomeGreeting;
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
                      greeting: greeting,
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
            destination == UserHomeDestination.pasatiempos ||
            destination == UserHomeDestination.quieroHablar;
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
              conversationTopicController == null
                  ? UserPlaceholderPage.quieroHablar()
                  : UserConversationTopicsPage(
                      topicController: conversationTopicController!,
                      sessionController: conversationSession,
                    ),
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
    this.conversationTopicController,
    this.memoryController,
    this.observationController,
    this.supportedPersonProfileController,
    this.syncController,
    this.privacyController,
    this.autoload = true,
    this.initialSection = FeatureSection.routines,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.enableQuietRemotePull = false,
  });

  final FamilyRoutineController controller;
  final FamilyPastimeController? pastimeController;
  final FamilyConversationTopicController? conversationTopicController;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final FamilySupportedPersonProfileController?
  supportedPersonProfileController;
  final SyncPresentationController? syncController;
  final PrivacyPresentationController? privacyController;
  final SyntheticPersona persona;
  final bool autoload;
  final FeatureSection initialSection;
  final DemoDataScope demoDataScope;

  /// Quiet pull when entering Pasatiempos/Conversaciones/profile in shared demo.
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
        await widget.conversationTopicController?.load();
        await widget.memoryController?.load();
        _syncApprovedMemoriesOntoTopics();
        await widget.observationController?.load();
        await widget.supportedPersonProfileController?.load();
        await widget.syncController?.load();
        await widget.privacyController?.load();
        if (_section == FeatureSection.pastimes ||
            _section == FeatureSection.conversations ||
            _section == FeatureSection.supportedPersonProfile) {
          await _quietPullFamilyContent();
        }
      });
    } else if (widget.enableQuietRemotePull &&
        (_section == FeatureSection.pastimes ||
            _section == FeatureSection.conversations ||
            _section == FeatureSection.supportedPersonProfile)) {
      // Real executable: main() already called composition.load(); still pull.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quietPullFamilyContent();
      });
    }
  }

  void _syncApprovedMemoriesOntoTopics() {
    final topics = widget.conversationTopicController;
    final memories = widget.memoryController;
    if (topics == null || memories == null) {
      return;
    }
    topics.setApprovedMemories(memories.memories);
  }

  Future<void> _quietPullFamilyContent() async {
    if (!widget.enableQuietRemotePull) {
      return;
    }
    final generation = ++_quietPullGeneration;
    final pastime = widget.pastimeController;
    final topics = widget.conversationTopicController;
    final profile = widget.supportedPersonProfileController;
    if (pastime != null) {
      await pastime.refreshFromSharedRemote();
    }
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
    if (topics != null) {
      await topics.refreshFromSharedRemote();
    }
    if (!mounted || generation != _quietPullGeneration) {
      return;
    }
    if (profile != null) {
      await profile.refreshFromSharedRemote();
    }
    _syncApprovedMemoriesOntoTopics();
  }

  void _selectSection(FeatureSection section) {
    setState(() => _section = section);
    if (section == FeatureSection.pastimes ||
        section == FeatureSection.conversations ||
        section == FeatureSection.supportedPersonProfile) {
      _quietPullFamilyContent();
    }
    if (section == FeatureSection.conversations) {
      _syncApprovedMemoriesOntoTopics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MemoraCopy.brandTitle,
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.light(),
      home: _FamilyShell(
        routineController: widget.controller,
        pastimeController: widget.pastimeController,
        conversationTopicController: widget.conversationTopicController,
        memoryController: widget.memoryController,
        observationController: widget.observationController,
        supportedPersonProfileController:
            widget.supportedPersonProfileController,
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
    required this.conversationTopicController,
    required this.memoryController,
    required this.observationController,
    required this.supportedPersonProfileController,
    required this.syncController,
    required this.privacyController,
    required this.persona,
    required this.section,
    required this.onSection,
    required this.demoDataScope,
  });

  final FamilyRoutineController routineController;
  final FamilyPastimeController? pastimeController;
  final FamilyConversationTopicController? conversationTopicController;
  final FamilyMemoryController? memoryController;
  final FamilyObservationController? observationController;
  final FamilySupportedPersonProfileController?
  supportedPersonProfileController;
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
      if (conversationTopicController != null) FeatureSection.conversations,
      if (memoryController != null) FeatureSection.memories,
      if (observationController != null) FeatureSection.observations,
      if (supportedPersonProfileController != null)
        FeatureSection.supportedPersonProfile,
      if (syncController != null) FeatureSection.sync,
      if (privacyController != null) FeatureSection.privacy,
      FeatureSection.help,
    ];
    final listenables = <Listenable>[routineController];
    if (pastimeController != null) {
      listenables.add(pastimeController!);
    }
    if (conversationTopicController != null) {
      listenables.add(conversationTopicController!);
    }
    if (memoryController != null) {
      listenables.add(memoryController!);
    }
    if (observationController != null) {
      listenables.add(observationController!);
    }
    if (supportedPersonProfileController != null) {
      listenables.add(supportedPersonProfileController!);
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
        final showSyncStatus = _familyNeedsActionableSyncNotice(
          section: section,
          routineController: routineController,
          pastimeController: pastimeController,
          conversationTopicController: conversationTopicController,
          memoryController: memoryController,
          supportedPersonProfileController: supportedPersonProfileController,
          syncController: syncController,
        );
        final syncLabel = switch (section) {
          FeatureSection.sync =>
            syncController?.syncChromeLabel ?? MemoraCopy.syncNeedsAttention,
          FeatureSection.pastimes =>
            pastimeController?.syncLabel ?? MemoraCopy.syncNeedsAttention,
          FeatureSection.conversations =>
            conversationTopicController?.syncLabel ??
                MemoraCopy.syncNeedsAttention,
          FeatureSection.memories =>
            memoryController?.syncLabel ?? MemoraCopy.syncNeedsAttention,
          FeatureSection.supportedPersonProfile =>
            supportedPersonProfileController?.syncLabel ??
                MemoraCopy.syncNeedsAttention,
          _ =>
            syncController?.unresolved.isNotEmpty == true
                ? syncController!.syncChromeLabel
                : MemoraCopy.syncNeedsAttention,
        };
        final syncAction = switch (section) {
          FeatureSection.sync =>
            syncController?.needsActionableSyncNotice == true
                ? syncController!.recoveryActionLabel
                : null,
          FeatureSection.pastimes =>
            pastimeController?.needsActionableSyncNotice == true
                ? pastimeController!.recoveryActionLabel
                : null,
          FeatureSection.conversations =>
            conversationTopicController?.needsActionableSyncNotice == true
                ? conversationTopicController!.recoveryActionLabel
                : null,
          FeatureSection.memories =>
            memoryController?.needsActionableSyncNotice == true
                ? memoryController!.recoveryActionLabel
                : null,
          FeatureSection.supportedPersonProfile =>
            supportedPersonProfileController?.needsActionableSyncNotice == true
                ? supportedPersonProfileController!.recoveryActionLabel
                : null,
          _ =>
            syncController?.unresolved.isNotEmpty == true
                ? syncController!.recoveryActionLabel
                : null,
        };
        final onSync = syncAction == null
            ? null
            : () {
                if (section == FeatureSection.sync ||
                    syncController?.unresolved.isNotEmpty == true) {
                  syncController?.recover();
                } else if (section == FeatureSection.pastimes) {
                  pastimeController?.recover();
                } else if (section == FeatureSection.conversations) {
                  conversationTopicController?.recover();
                } else if (section == FeatureSection.memories) {
                  memoryController?.recover();
                } else if (section == FeatureSection.supportedPersonProfile) {
                  supportedPersonProfileController?.recover();
                } else {
                  routineController.recover();
                }
              };
        // One heading hierarchy: shell section title only (pages omit duplicates).
        final sectionTitle = switch (section) {
          FeatureSection.routines => MemoraCopy.familyHomeTitle,
          FeatureSection.pastimes => MemoraCopy.pastimesSectionTitle,
          FeatureSection.conversations => MemoraCopy.conversationsSectionTitle,
          FeatureSection.memories => MemoraCopy.memoriesTitle,
          FeatureSection.observations => MemoraCopy.observationsTitle,
          FeatureSection.supportedPersonProfile =>
            MemoraCopy.supportedPersonProfileSectionTitle,
          FeatureSection.sync => MemoraCopy.syncSectionTitle,
          FeatureSection.privacy => MemoraCopy.privacySectionTitle,
          FeatureSection.help => MemoraCopy.helpAboutTitle,
        };
        final showPreferredNameCta =
            section == FeatureSection.routines &&
            supportedPersonProfileController?.needsPreferredNameSetup == true;

        return ShellScaffold(
          target: ExperienceTarget.familyWeb,
          persona: persona,
          chromeMode: ShellChromeMode.product,
          sectionTitle: sectionTitle,
          showSyncStatus: showSyncStatus,
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
              if (showPreferredNameCta) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const Key('memora-configure-preferred-name-cta'),
                  onPressed: () =>
                      onSection(FeatureSection.supportedPersonProfile),
                  child: const Text(MemoraCopy.configurePreferredNameCta),
                ),
              ],
              const SizedBox(height: 20),
              switch (section) {
                FeatureSection.routines => FamilyRoutineConfigureContent(
                  controller: routineController,
                ),
                FeatureSection.pastimes => FamilyPastimeConfigureContent(
                  controller: pastimeController!,
                ),
                FeatureSection.conversations =>
                  FamilyConversationTopicConfigureContent(
                    controller: conversationTopicController!,
                  ),
                FeatureSection.memories => FamilyMemoryPage(
                  controller: memoryController!,
                ),
                FeatureSection.observations => FamilyObservationPage(
                  controller: observationController!,
                ),
                FeatureSection.supportedPersonProfile =>
                  FamilySupportedPersonProfilePage(
                    controller: supportedPersonProfileController!,
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

bool _familyNeedsActionableSyncNotice({
  required FeatureSection section,
  required FamilyRoutineController routineController,
  required FamilyPastimeController? pastimeController,
  required FamilyConversationTopicController? conversationTopicController,
  required FamilyMemoryController? memoryController,
  required FamilySupportedPersonProfileController?
  supportedPersonProfileController,
  required SyncPresentationController? syncController,
}) {
  if (syncController?.unresolved.isNotEmpty == true) {
    return true;
  }
  if (syncController?.needsActionableSyncNotice == true &&
      section == FeatureSection.sync) {
    return true;
  }
  return switch (section) {
    FeatureSection.pastimes =>
      pastimeController?.needsActionableSyncNotice == true,
    FeatureSection.conversations =>
      conversationTopicController?.needsActionableSyncNotice == true,
    FeatureSection.memories =>
      memoryController?.needsActionableSyncNotice == true,
    FeatureSection.supportedPersonProfile =>
      supportedPersonProfileController?.needsActionableSyncNotice == true,
    FeatureSection.routines => routineController.needsActionableSyncNotice,
    _ => false,
  };
}
