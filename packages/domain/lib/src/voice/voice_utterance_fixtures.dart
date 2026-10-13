import 'home_guidance_destination.dart';
import 'voice_content_snapshot.dart';
import 'voice_guidance_decision.dart';
import 'voice_intent.dart';

/// One fictional Spanish utterance case for table-driven matcher/policy tests.
final class VoiceUtteranceFixture {
  const VoiceUtteranceFixture({
    required this.id,
    required this.utterance,
    required this.expectedIntent,
    required this.content,
    required this.expectedKind,
    this.expectedDestination,
    this.expectTalkPlaceholder = false,
  });

  final String id;
  final String utterance;
  final VoiceIntentClass expectedIntent;
  final VoiceContentSnapshot content;
  final VoiceGuidanceKind expectedKind;
  final HomeGuidanceDestination? expectedDestination;
  final bool expectTalkPlaceholder;
}

/// Exhaustive fictional Spanish fixtures covering Slice 9 intent classes.
abstract final class VoiceUtteranceFixtures {
  static const VoiceContentSnapshot _full = VoiceContentSnapshot.allAvailable;
  static const VoiceContentSnapshot _none = VoiceContentSnapshot.empty;
  static const VoiceContentSnapshot _pastimesOnly = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: false,
    hasActivePastimes: true,
    hasApprovedMemories: false,
  );
  static const VoiceContentSnapshot _memoriesOnly = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: false,
    hasActivePastimes: false,
    hasApprovedMemories: true,
  );
  static const VoiceContentSnapshot _miDiaOnly = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: true,
    hasActivePastimes: false,
    hasApprovedMemories: false,
  );
  static const VoiceContentSnapshot _noMiDia = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: false,
    hasActivePastimes: true,
    hasApprovedMemories: true,
  );

  static const List<VoiceUtteranceFixture> all = <VoiceUtteranceFixture>[
    // --- Routine / now → Mi día ---
    VoiceUtteranceFixture(
      id: 'routine_mi_dia',
      utterance: 'Quiero ver mi día',
      expectedIntent: VoiceIntentClass.routineNow,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),
    VoiceUtteranceFixture(
      id: 'routine_que_tengo',
      utterance: '¿Qué tengo que hacer?',
      expectedIntent: VoiceIntentClass.routineNow,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),
    VoiceUtteranceFixture(
      id: 'routine_siguiente_paso',
      utterance: 'El siguiente paso',
      expectedIntent: VoiceIntentClass.routineNow,
      content: _none,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),
    VoiceUtteranceFixture(
      id: 'routine_rutina',
      utterance: 'Mi rutina de hoy',
      expectedIntent: VoiceIntentClass.routineNow,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),

    // --- Activity → Pasatiempos when available ---
    VoiceUtteranceFixture(
      id: 'activity_pasatiempos',
      utterance: 'Quiero un pasatiempo',
      expectedIntent: VoiceIntentClass.activity,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.pasatiempos,
    ),
    VoiceUtteranceFixture(
      id: 'activity_aburrido',
      utterance: 'Estoy aburrido',
      expectedIntent: VoiceIntentClass.activity,
      content: _pastimesOnly,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.pasatiempos,
    ),
    VoiceUtteranceFixture(
      id: 'activity_entretenimiento',
      utterance: 'Algo para entretener',
      expectedIntent: VoiceIntentClass.activity,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.pasatiempos,
    ),
    VoiceUtteranceFixture(
      id: 'activity_skip_unavailable',
      utterance: 'Quiero hacer algo',
      expectedIntent: VoiceIntentClass.activity,
      content: _none,
      expectedKind: VoiceGuidanceKind.nothingPrepared,
    ),

    // --- Memories → Recuerdos when available ---
    VoiceUtteranceFixture(
      id: 'memory_fotos',
      utterance: 'Quiero ver fotos',
      expectedIntent: VoiceIntentClass.memories,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.recuerdos,
    ),
    VoiceUtteranceFixture(
      id: 'memory_recuerdos',
      utterance: 'Ver recuerdos de la familia',
      expectedIntent: VoiceIntentClass.memories,
      content: _memoriesOnly,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.recuerdos,
    ),
    VoiceUtteranceFixture(
      id: 'memory_skip_unavailable',
      utterance: 'Fotografías',
      expectedIntent: VoiceIntentClass.memories,
      content: _none,
      expectedKind: VoiceGuidanceKind.nothingPrepared,
    ),

    // --- Explicit talk → Quiero hablar with honesty ---
    VoiceUtteranceFixture(
      id: 'talk_quiero_hablar',
      utterance: 'Quiero hablar',
      expectedIntent: VoiceIntentClass.explicitTalk,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.quieroHablar,
      expectTalkPlaceholder: true,
    ),
    VoiceUtteranceFixture(
      id: 'talk_llamar',
      utterance: 'Quiero llamar',
      expectedIntent: VoiceIntentClass.explicitTalk,
      content: _none,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.quieroHablar,
      expectTalkPlaceholder: true,
    ),
    VoiceUtteranceFixture(
      id: 'talk_telefono',
      utterance: 'Usar el teléfono',
      expectedIntent: VoiceIntentClass.explicitTalk,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.quieroHablar,
      expectTalkPlaceholder: true,
    ),

    // --- Generic priority ---
    VoiceUtteranceFixture(
      id: 'generic_prefers_mi_dia',
      utterance: 'No sé qué hacer',
      expectedIntent: VoiceIntentClass.genericHelp,
      content: _full,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),
    VoiceUtteranceFixture(
      id: 'generic_skips_to_pasatiempos',
      utterance: 'Ayúdame a elegir',
      expectedIntent: VoiceIntentClass.genericHelp,
      content: _noMiDia,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.pasatiempos,
    ),
    VoiceUtteranceFixture(
      id: 'generic_skips_to_recuerdos',
      utterance: 'Recomiéndame algo',
      expectedIntent: VoiceIntentClass.genericHelp,
      content: _memoriesOnly,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.recuerdos,
    ),
    VoiceUtteranceFixture(
      id: 'generic_nothing_prepared',
      utterance: 'No sé',
      expectedIntent: VoiceIntentClass.genericHelp,
      content: _none,
      expectedKind: VoiceGuidanceKind.nothingPrepared,
    ),
    VoiceUtteranceFixture(
      id: 'generic_mi_dia_only',
      utterance: 'Estoy perdido',
      expectedIntent: VoiceIntentClass.genericHelp,
      content: _miDiaOnly,
      expectedKind: VoiceGuidanceKind.suggestDestination,
      expectedDestination: HomeGuidanceDestination.miDia,
    ),

    // --- Unclear — no guess ---
    VoiceUtteranceFixture(
      id: 'unclear_weather',
      utterance: '¿Va a llover mañana en Demo?',
      expectedIntent: VoiceIntentClass.unclear,
      content: _full,
      expectedKind: VoiceGuidanceKind.unclear,
    ),
    VoiceUtteranceFixture(
      id: 'unclear_gibberish',
      utterance: 'blip blop Ejemplo',
      expectedIntent: VoiceIntentClass.unclear,
      content: _full,
      expectedKind: VoiceGuidanceKind.unclear,
    ),
    VoiceUtteranceFixture(
      id: 'unclear_empty',
      utterance: '   ',
      expectedIntent: VoiceIntentClass.unclear,
      content: _full,
      expectedKind: VoiceGuidanceKind.unclear,
    ),

    // --- Safety-sensitive — fixed limitation, never a destination ---
    VoiceUtteranceFixture(
      id: 'safety_emergencias',
      utterance: 'Llama a emergencias',
      expectedIntent: VoiceIntentClass.safetySensitive,
      content: _full,
      expectedKind: VoiceGuidanceKind.safetyLimitation,
    ),
    VoiceUtteranceFixture(
      id: 'safety_pecho',
      utterance: 'Me duele el pecho',
      expectedIntent: VoiceIntentClass.safetySensitive,
      content: _full,
      expectedKind: VoiceGuidanceKind.safetyLimitation,
    ),
    VoiceUtteranceFixture(
      id: 'safety_medicina',
      utterance: '¿Qué medicina tomo?',
      expectedIntent: VoiceIntentClass.safetySensitive,
      content: _full,
      expectedKind: VoiceGuidanceKind.safetyLimitation,
    ),
    VoiceUtteranceFixture(
      id: 'safety_ambulancia',
      utterance: 'Necesito una ambulancia',
      expectedIntent: VoiceIntentClass.safetySensitive,
      content: _none,
      expectedKind: VoiceGuidanceKind.safetyLimitation,
    ),
  ];
}
