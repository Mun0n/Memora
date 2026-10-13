import 'home_guidance_destination.dart';

/// Normative Spanish strings for voice guidance outcomes (Slice 9).
///
/// Presentation may mirror these in `MemoraCopy`; tests assert against these
/// constants so copy stays locked to the specification.
abstract final class VoiceGuidanceCopy {
  static const String permissionExplain =
      'El micrófono se usa solo mientras te ayudamos a elegir';

  static const String listeningPrompt =
      'Te estoy escuchando… Dime qué te gustaría hacer';

  static const String unclear =
      'No te he entendido. Puedo ayudarte a elegir entre las opciones de '
      'esta pantalla';

  static const String nothingPrepared =
      'Ahora mismo no tengo una actividad preparada para recomendarte';

  static const String safetyLimitation =
      'Memora no es un servicio médico ni de emergencias. No diagnostica, '
      'no aconseja tratamientos ni afirma que se haya contactado con ayuda. '
      'Si necesitas ayuda urgente, usa los canales de emergencia de tu zona.';

  static const String recognizerUnavailable =
      'Ahora no puedo escucharte. Puedes elegir una de las cuatro opciones';

  /// Honest `Quiero hablar` suggestion — never claims a call is available.
  static const String suggestQuieroHablar =
      'Te recomiendo Quiero hablar. Desde aquí no se hace ninguna llamada. '
      '¿Quieres ir ahora?';

  static String suggestDestination(HomeGuidanceDestination destination) {
    return switch (destination) {
      HomeGuidanceDestination.miDia =>
        'Te recomiendo Mi día. ¿Quieres ir ahora?',
      HomeGuidanceDestination.pasatiempos =>
        'Te recomiendo Pasatiempos. ¿Quieres ir ahora?',
      HomeGuidanceDestination.recuerdos =>
        'Te recomiendo Recuerdos. ¿Quieres ir ahora?',
      HomeGuidanceDestination.quieroHablar => suggestQuieroHablar,
    };
  }

  static String goToLabel(HomeGuidanceDestination destination) {
    return switch (destination) {
      HomeGuidanceDestination.miDia => 'Ir a Mi día',
      HomeGuidanceDestination.pasatiempos => 'Ir a Pasatiempos',
      HomeGuidanceDestination.recuerdos => 'Ir a Recuerdos',
      HomeGuidanceDestination.quieroHablar => 'Ir a Quiero hablar',
    };
  }
}
