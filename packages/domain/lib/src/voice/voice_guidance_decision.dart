import 'home_guidance_destination.dart';
import 'voice_guidance_copy.dart';
import 'voice_intent.dart';

/// Kind of voice guidance outcome. At most one destination is ever suggested.
enum VoiceGuidanceKind {
  /// Exactly one allowed home destination with confirm-before-navigate copy.
  suggestDestination,

  /// Unclear speech — no guess.
  unclear,

  /// No usable destination given local content / intent.
  nothingPrepared,

  /// Medical / danger / emergency language — fixed limitation only.
  safetyLimitation,
}

/// Pure recommendation result. Holds no transcript and is not intended for
/// persistence, audit, sync or analytics.
final class VoiceGuidanceDecision {
  const VoiceGuidanceDecision._({
    required this.kind,
    required this.intent,
    required this.message,
    this.destination,
    this.usesTalkHonestyWording = false,
  });

  final VoiceGuidanceKind kind;
  final VoiceIntentClass intent;

  /// Plain Spanish message for the written suggestion / notice.
  final String message;

  /// Present only when [kind] is [VoiceGuidanceKind.suggestDestination].
  final HomeGuidanceDestination? destination;

  /// True when suggesting `Quiero hablar` with honest non-telephone wording.
  final bool usesTalkHonestyWording;

  /// Backward-compatible alias used by Slice 9 tests/callers.
  bool get usesTalkPlaceholderWording => usesTalkHonestyWording;

  bool get suggestsDestination =>
      kind == VoiceGuidanceKind.suggestDestination && destination != null;

  factory VoiceGuidanceDecision.suggest({
    required HomeGuidanceDestination destination,
    required VoiceIntentClass intent,
  }) {
    final talk = destination == HomeGuidanceDestination.quieroHablar;
    return VoiceGuidanceDecision._(
      kind: VoiceGuidanceKind.suggestDestination,
      intent: intent,
      destination: destination,
      usesTalkHonestyWording: talk,
      message: VoiceGuidanceCopy.suggestDestination(destination),
    );
  }

  factory VoiceGuidanceDecision.unclear({
    VoiceIntentClass intent = VoiceIntentClass.unclear,
  }) {
    return VoiceGuidanceDecision._(
      kind: VoiceGuidanceKind.unclear,
      intent: intent,
      message: VoiceGuidanceCopy.unclear,
    );
  }

  factory VoiceGuidanceDecision.nothingPrepared({
    required VoiceIntentClass intent,
  }) {
    return VoiceGuidanceDecision._(
      kind: VoiceGuidanceKind.nothingPrepared,
      intent: intent,
      message: VoiceGuidanceCopy.nothingPrepared,
    );
  }

  factory VoiceGuidanceDecision.safetyLimitation() {
    return const VoiceGuidanceDecision._(
      kind: VoiceGuidanceKind.safetyLimitation,
      intent: VoiceIntentClass.safetySensitive,
      message: VoiceGuidanceCopy.safetyLimitation,
    );
  }
}
