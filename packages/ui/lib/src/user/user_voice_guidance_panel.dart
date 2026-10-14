import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';
import 'user_voice_guidance_controller.dart';

/// Modal chrome for voice guidance states. Home tiles stay one action away.
class UserVoiceGuidancePanel extends StatelessWidget {
  const UserVoiceGuidancePanel({
    super.key,
    required this.controller,
    required this.onConfirmNavigate,
  });

  final UserVoiceGuidanceController controller;
  final VoidCallback onConfirmNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) {
          return const SizedBox.shrink();
        }
        return Material(
          key: const Key('memora-user-voice-panel'),
          color: MemoraTheme.highContrastSurface.withValues(alpha: 0.97),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _VoicePanelBody(
                controller: controller,
                onConfirmNavigate: onConfirmNavigate,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VoicePanelBody extends StatelessWidget {
  const _VoicePanelBody({
    required this.controller,
    required this.onConfirmNavigate,
  });

  final UserVoiceGuidanceController controller;
  final VoidCallback onConfirmNavigate;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final textTheme = Theme.of(context).textTheme;
    final message = c.message ?? '';
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.phase == VoiceGuidancePhase.listening)
            _ListeningIndicator(reduceMotion: reduceMotion),
          if (c.phase == VoiceGuidancePhase.processing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                MemoraCopy.voiceProcessing,
                key: const Key('memora-user-voice-processing'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: MemoraSupportedPersonTypography.secondary,
                  height: MemoraSupportedPersonTypography.bodyHeight,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (c.recognizedText case final recognized?) ...[
                      Text(
                        MemoraCopy.voiceUnderstood,
                        style: textTheme.titleMedium?.copyWith(
                          color: MemoraTheme.highContrastInk,
                          fontWeight: FontWeight.w600,
                          fontSize: MemoraSupportedPersonTypography.secondary,
                          height: MemoraSupportedPersonTypography.bodyHeight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        key: const Key('memora-user-voice-transcript'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: MemoraTheme.accentBand.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          recognized,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: MemoraTheme.highContrastInk,
                            fontWeight: FontWeight.w700,
                            fontSize: MemoraSupportedPersonTypography.title,
                            height: MemoraSupportedPersonTypography.bodyHeight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      message,
                      key: const Key('memora-user-voice-message'),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: MemoraTheme.highContrastInk,
                        fontWeight: FontWeight.w700,
                        fontSize: MemoraSupportedPersonTypography.heading,
                        height: MemoraSupportedPersonTypography.bodyHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ..._actions(c),
        ],
      ),
    );
  }

  List<Widget> _actions(UserVoiceGuidanceController c) {
    switch (c.phase) {
      case VoiceGuidancePhase.idle:
        return const [];
      case VoiceGuidancePhase.permissionExplain:
        return [
          _largeFilled(
            key: const Key('memora-user-voice-continue'),
            label: MemoraCopy.voiceContinue,
            onPressed: c.confirmPermissionAndListen,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceCancel,
            onPressed: c.cancel,
          ),
        ];
      case VoiceGuidancePhase.permissionRequesting:
        return [
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceCancel,
            onPressed: c.cancel,
          ),
        ];
      case VoiceGuidancePhase.listening:
      case VoiceGuidancePhase.processing:
        return [
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceNotNow,
            onPressed: c.dismissToHome,
          ),
        ];
      case VoiceGuidancePhase.suggestion:
        final dest = c.suggestedDestination!;
        return [
          _largeFilled(
            key: const Key('memora-user-voice-go'),
            label: VoiceGuidanceCopy.goToLabel(dest),
            onPressed: onConfirmNavigate,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-retry'),
            label: MemoraCopy.voiceRetry,
            onPressed: c.retry,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceCancel,
            onPressed: c.cancel,
          ),
        ];
      case VoiceGuidancePhase.unclear:
      case VoiceGuidancePhase.silence:
      case VoiceGuidancePhase.timeout:
      case VoiceGuidancePhase.error:
        return [
          _largeFilled(
            key: const Key('memora-user-voice-retry'),
            label: MemoraCopy.voiceRetry,
            onPressed: c.retry,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-manual'),
            label: MemoraCopy.voiceChooseManually,
            onPressed: c.dismissToHome,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceCancel,
            onPressed: c.cancel,
          ),
        ];
      case VoiceGuidancePhase.nothingPrepared:
      case VoiceGuidancePhase.safetyLimitation:
      case VoiceGuidancePhase.unavailable:
      case VoiceGuidancePhase.permissionDenied:
        return [
          _largeFilled(
            key: const Key('memora-user-voice-manual'),
            label: MemoraCopy.voiceChooseManually,
            onPressed: c.dismissToHome,
          ),
          const SizedBox(height: 12),
          _largeOutlined(
            key: const Key('memora-user-voice-cancel'),
            label: MemoraCopy.voiceCancel,
            onPressed: c.cancel,
          ),
        ];
    }
  }

  Widget _largeFilled({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton(key: key, onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _largeOutlined({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            MemoraTheme.minTouchExtent,
            MemoraTheme.preferredTouchExtent + 8,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ListeningIndicator extends StatefulWidget {
  const _ListeningIndicator({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0,
      upperBound: 1,
    );
    if (!widget.reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ListeningIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion == oldWidget.reduceMotion) {
      return;
    }
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('memora-user-voice-listening-indicator'),
      height: 112,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = widget.reduceMotion ? 0.0 : _controller.value;
            return Container(
              width: 72 + (progress * 18),
              height: 72 + (progress * 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MemoraTheme.accentBand.withValues(
                  alpha: 0.18 + (progress * 0.16),
                ),
                border: Border.all(color: MemoraTheme.accentBand, width: 3),
              ),
              child: const Icon(
                Icons.mic,
                size: 38,
                color: MemoraTheme.highContrastInk,
              ),
            );
          },
        ),
      ),
    );
  }
}
