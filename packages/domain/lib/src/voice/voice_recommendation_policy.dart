import 'home_guidance_destination.dart';
import 'voice_content_snapshot.dart';
import 'voice_guidance_decision.dart';
import 'voice_intent.dart';
import 'voice_intent_matcher.dart';

/// Pure deterministic recommendation policy for home voice guidance.
///
/// Inputs: ephemeral recognized text + local [VoiceContentSnapshot].
/// Output: at most one destination suggestion or a fixed non-destination
/// outcome. Does not persist, log, sync or send the transcript.
abstract final class VoiceRecommendationPolicy {
  /// Classifies [textInMemory] and selects zero or one allowed suggestion.
  ///
  /// [textInMemory] must not be stored by callers after this returns.
  static VoiceGuidanceDecision recommend({
    required String? textInMemory,
    required VoiceContentSnapshot content,
  }) {
    final intent = VoiceIntentMatcher.classify(textInMemory);
    return forIntent(intent: intent, content: content);
  }

  /// Maps an already-classified intent + local content to a decision.
  static VoiceGuidanceDecision forIntent({
    required VoiceIntentClass intent,
    required VoiceContentSnapshot content,
  }) {
    switch (intent) {
      case VoiceIntentClass.safetySensitive:
        return VoiceGuidanceDecision.safetyLimitation();

      case VoiceIntentClass.unclear:
        return VoiceGuidanceDecision.unclear();

      case VoiceIntentClass.routineNow:
        return VoiceGuidanceDecision.suggest(
          destination: HomeGuidanceDestination.miDia,
          intent: intent,
        );

      case VoiceIntentClass.activity:
        if (content.hasActivePastimes) {
          return VoiceGuidanceDecision.suggest(
            destination: HomeGuidanceDestination.pasatiempos,
            intent: intent,
          );
        }
        return VoiceGuidanceDecision.nothingPrepared(intent: intent);

      case VoiceIntentClass.memories:
        if (content.hasApprovedMemories) {
          return VoiceGuidanceDecision.suggest(
            destination: HomeGuidanceDestination.recuerdos,
            intent: intent,
          );
        }
        return VoiceGuidanceDecision.nothingPrepared(intent: intent);

      case VoiceIntentClass.explicitTalk:
        // Availability depends on cached active topics; still confirm-before-nav.
        // Never a telephone feature.
        if (content.hasActiveConversationTopics) {
          return VoiceGuidanceDecision.suggest(
            destination: HomeGuidanceDestination.quieroHablar,
            intent: intent,
          );
        }
        return VoiceGuidanceDecision.nothingPrepared(intent: intent);

      case VoiceIntentClass.genericHelp:
        return _genericPriority(content);
    }
  }

  /// Normative generic priority: Mi día → Pasatiempos → Recuerdos.
  /// `Quiero hablar` is never selected by profiling conversation need.
  static VoiceGuidanceDecision _genericPriority(VoiceContentSnapshot content) {
    const intent = VoiceIntentClass.genericHelp;
    if (content.hasCurrentOrPendingMiDia) {
      return VoiceGuidanceDecision.suggest(
        destination: HomeGuidanceDestination.miDia,
        intent: intent,
      );
    }
    if (content.hasActivePastimes) {
      return VoiceGuidanceDecision.suggest(
        destination: HomeGuidanceDestination.pasatiempos,
        intent: intent,
      );
    }
    if (content.hasApprovedMemories) {
      return VoiceGuidanceDecision.suggest(
        destination: HomeGuidanceDestination.recuerdos,
        intent: intent,
      );
    }
    return VoiceGuidanceDecision.nothingPrepared(intent: intent);
  }
}
