import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'experience_target.dart';

/// Empty non-production placeholder shared by tablet, caregiver and web shells.
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: highContrastSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: minTouchExtent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: accentBand,
                child: Text(
                  'DEMOSTRACIÓN — NO PRODUCCIÓN',
                  semanticsLabel: 'Entorno de demostración, no producción',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Memora · ${target.englishLabel}',
                semanticsLabel: target.semanticsLabel,
                style: textTheme.headlineMedium?.copyWith(
                  color: highContrastInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${target.spanishLabel} · cáscara vacía (Slice 1)',
                style: textTheme.titleLarge?.copyWith(color: highContrastInk),
              ),
              const SizedBox(height: 24),
              Text(
                'Persona sintética: ${persona.displayName}',
                style: textTheme.titleMedium?.copyWith(
                  color: highContrastInk,
                  fontSize: 22,
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
                  constraints: const BoxConstraints(minHeight: minTouchExtent),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: highContrastInk, width: 2),
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
                'Sin funciones de producto. Sin datos reales. Sin conexión remota.',
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
