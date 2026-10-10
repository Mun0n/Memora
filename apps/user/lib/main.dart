import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

void main() {
  runApp(
    const MemoraShellApp(
      target: ExperienceTarget.user,
      persona: SyntheticFixtures.amparoDemo,
    ),
  );
}
