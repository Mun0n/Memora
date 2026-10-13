/// Fixed reviewed Spanish copy for guided conversations (Slice 10).
///
/// All non-family-authored sentences come from here. Never scores, corrects,
/// claims understanding, offers medical advice or promises emergency help.
abstract final class ConversationCopy {
  static const String neutralAcknowledgement = 'Gracias por contármelo';

  static const String silenceRecovery =
      'No pasa nada. Podemos seguir, cambiar de tema o terminar';

  static const String noMeAcuerdoRecovery =
      'No pasa nada. Podemos hablar de otra cosa';

  static const String recognitionFailureRecovery =
      'No te he entendido. Puedes repetir, cambiar de tema o terminar';

  static const String safetyLimitation =
      'Memora no es un servicio médico ni de emergencias. No diagnostica, '
      'no aconseja tratamientos ni afirma que se haya contactado con ayuda. '
      'Si necesitas ayuda urgente, usa los canales de emergencia de tu zona.';

  static const String unavailable =
      'Ahora no puedo escucharte. Puedes leer el tema y usar los botones '
      'para seguir o terminar';

  /// Local Spanish speech output unavailable — written flow remains usable.
  static const String speechOutputUnavailable =
      'Ahora no puedo hablar en voz alta. Puedes leer el texto y pulsar '
      'Hablar cuando quieras que te escuche.';

  static const String memoraSpeakingLabel = 'Memora está hablando';

  static const String listeningLabel = 'Te escucho';

  static const String emptyTopicsInvitation =
      'Tu familia aún no ha preparado una conversación. Puedes volver al inicio.';

  static const String topicListInvitation =
      'Elige un tema familiar cuando quieras hablar un rato.';

  static const String pickForMeLabel = 'Elige tú por mí';

  static const String startConversationLabel = 'Empezar';

  static const String finishedSpeakingLabel = 'He terminado';

  /// Manual listen start when local speech output is unavailable.
  static const String manualSpeakLabel = 'Hablar';

  static const String repeatLabel = 'Repetir';

  static const String changeTopicLabel = 'Cambiar de tema';

  static const String finishLabel = 'Terminar';
}
