import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../experience_target.dart';
import '../family/family_routine_configure_page.dart';
import '../family/family_routine_controller.dart';
import '../theme/memora_theme.dart';
import '../user/user_routine_controller.dart';
import '../user/user_routine_home.dart';

/// Supported-person app shell wired to a [UserRoutineController].
class MemoraUserApp extends StatefulWidget {
  const MemoraUserApp({
    super.key,
    required this.controller,
    required this.persona,
    this.autoload = true,
  });

  final UserRoutineController controller;
  final SyntheticPersona persona;

  /// When true, triggers [UserRoutineController.load] after the first frame.
  final bool autoload;

  @override
  State<MemoraUserApp> createState() => _MemoraUserAppState();
}

class _MemoraUserAppState extends State<MemoraUserApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora ${ExperienceTarget.user.englishLabel} (demo)',
      debugShowCheckedModeBanner: true,
      theme: MemoraTheme.light(),
      home: UserRoutineHome(
        controller: widget.controller,
        persona: widget.persona,
      ),
    );
  }
}

/// Caregiver/family web app shell wired to a [FamilyRoutineController].
class MemoraFamilyWebApp extends StatefulWidget {
  const MemoraFamilyWebApp({
    super.key,
    required this.controller,
    required this.persona,
    this.autoload = true,
  });

  final FamilyRoutineController controller;
  final SyntheticPersona persona;
  final bool autoload;

  @override
  State<MemoraFamilyWebApp> createState() => _MemoraFamilyWebAppState();
}

class _MemoraFamilyWebAppState extends State<MemoraFamilyWebApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora ${ExperienceTarget.familyWeb.englishLabel} (demo)',
      debugShowCheckedModeBanner: true,
      theme: MemoraTheme.light(),
      home: FamilyRoutineConfigurePage(
        controller: widget.controller,
        persona: widget.persona,
      ),
    );
  }
}
