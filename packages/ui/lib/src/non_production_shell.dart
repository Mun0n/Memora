import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'experience_target.dart';

/// Viewport class used by shell layout adaptation (phone/tablet, narrow/desktop).
enum ShellViewportClass {
  compact,
  expanded;

  static const double expandedBreakpoint = 600;

  static ShellViewportClass fromWidth(double width) {
    return width >= expandedBreakpoint
        ? ShellViewportClass.expanded
        : ShellViewportClass.compact;
  }

  String get semanticsLabel => switch (this) {
    ShellViewportClass.compact => 'Compact shell layout',
    ShellViewportClass.expanded => 'Expanded shell layout',
  };

  Key get layoutKey => switch (this) {
    ShellViewportClass.compact => const Key('memora-shell-layout-compact'),
    ShellViewportClass.expanded => const Key('memora-shell-layout-expanded'),
  };
}

/// Empty non-production placeholder shared by user and web shells.
///
/// Shows only the experience label, synthetic persona markers and a plain sync
/// status. No product features, auth or remote calls.
class NonProductionShell extends StatelessWidget {
  const NonProductionShell({
    super.key,
    required this.target,
    required this.persona,
    this.syncStatusLabel =
        'Estado de sincronización: no conectado (demostración)',
  });

  final ExperienceTarget target;
  final SyntheticPersona persona;
  final String syncStatusLabel;

  static const Color highContrastInk = Color(0xFF121212);
  static const Color highContrastSurface = Color(0xFFF7F7F2);
  static const Color accentBand = Color(0xFF1F4B3A);
  static const double minTouchExtent = 48;
  static const double expandedContentMaxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final viewport = ShellViewportClass.fromWidth(width);
    final isExpanded = viewport == ShellViewportClass.expanded;
    final horizontalPadding = isExpanded ? 40.0 : 24.0;
    final verticalPadding = isExpanded ? 32.0 : 24.0;
    final titleStyle =
        (isExpanded ? textTheme.headlineMedium : textTheme.headlineSmall)
            ?.copyWith(color: highContrastInk, fontWeight: FontWeight.w700);

    return Scaffold(
      backgroundColor: highContrastSurface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isExpanded ? expandedContentMaxWidth : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          key: viewport.layoutKey,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              label: viewport.semanticsLabel,
                              excludeSemantics: true,
                              child: const SizedBox(width: 1, height: 1),
                            ),
                            Container(
                              constraints: const BoxConstraints(
                                minHeight: minTouchExtent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: accentBand,
                              child: Text(
                                'DEMOSTRACIÓN — NO PRODUCCIÓN',
                                semanticsLabel:
                                    'Entorno de demostración, no producción',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            SizedBox(height: isExpanded ? 36 : 28),
                            Text(
                              'Memora · ${target.englishLabel}',
                              semanticsLabel: target.semanticsLabel,
                              style: titleStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${target.spanishLabel} · '
                              'cáscara vacía (demostración)',
                              style: textTheme.titleLarge?.copyWith(
                                color: highContrastInk,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Persona sintética: ${persona.displayName}',
                              style: textTheme.titleMedium?.copyWith(
                                color: highContrastInk,
                                fontSize: isExpanded ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              persona.roleLabel,
                              style: textTheme.bodyLarge?.copyWith(
                                color: highContrastInk,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              persona.syntheticMarker,
                              style: textTheme.labelLarge?.copyWith(
                                color: highContrastInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: minTouchExtent,
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: highContrastInk,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  syncStatusLabel,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: highContrastInk,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin funciones de producto. Sin datos reales. '
                              'Sin conexión remota.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: highContrastInk,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin MaterialApp wrapper used by each executable shell entry point.
class MemoraShellApp extends StatelessWidget {
  const MemoraShellApp({
    super.key,
    required this.target,
    required this.persona,
  });

  final ExperienceTarget target;
  final SyntheticPersona persona;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora ${target.englishLabel} (demo)',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: NonProductionShell.accentBand,
          onPrimary: Colors.white,
          surface: NonProductionShell.highContrastSurface,
          onSurface: NonProductionShell.highContrastInk,
        ),
        textTheme: Typography.material2021().black.apply(
          bodyColor: NonProductionShell.highContrastInk,
          displayColor: NonProductionShell.highContrastInk,
        ),
      ),
      home: NonProductionShell(target: target, persona: persona),
    );
  }
}
