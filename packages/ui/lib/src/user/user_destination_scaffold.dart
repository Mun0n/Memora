import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';

/// Calm destination chrome: persistent return-home, no sync/persona/demo band.
class UserDestinationScaffold extends StatelessWidget {
  const UserDestinationScaffold({
    super.key,
    required this.onReturnHome,
    required this.body,
    this.scrollable = false,
  });

  final VoidCallback onReturnHome;
  final Widget body;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = width >= MemoraTheme.expandedBreakpoint;
    final horizontalPadding = isExpanded ? 40.0 : 24.0;
    final verticalPadding = isExpanded ? 28.0 : 20.0;

    final returnControl = Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        key: const Key('memora-user-return-home'),
        onPressed: onReturnHome,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
        ),
        child: const Text(MemoraCopy.returnHome),
      ),
    );

    final content = scrollable ? SingleChildScrollView(child: body) : body;

    return Scaffold(
      backgroundColor: MemoraTheme.highContrastSurface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              returnControl,
              const SizedBox(height: 16),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}
