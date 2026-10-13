import 'voice_intent.dart';

/// Spanish-first, localization-ready, deterministic intent matcher.
///
/// Uses explicit phrase/keyword fixtures — never probabilistic or generative.
/// Transcript is used only for the duration of [classify]; callers must not
/// persist it.
abstract final class VoiceIntentMatcher {
  /// Classifies one ephemeral Spanish utterance into a [VoiceIntentClass].
  static VoiceIntentClass classify(String? textInMemory) {
    final normalized = normalize(textInMemory);
    if (normalized.isEmpty) {
      return VoiceIntentClass.unclear;
    }

    // Safety first — never map medical/danger/emergency language to a tile.
    if (_matchesAny(normalized, _safetyPhrases)) {
      return VoiceIntentClass.safetySensitive;
    }

    // Explicit talk/call before generic activity phrasing.
    if (_matchesAny(normalized, _talkPhrases)) {
      return VoiceIntentClass.explicitTalk;
    }

    // Generic help-choosing before broad "qué hacer" activity cues.
    if (_matchesAny(normalized, _genericPhrases)) {
      return VoiceIntentClass.genericHelp;
    }

    if (_matchesAny(normalized, _routinePhrases)) {
      return VoiceIntentClass.routineNow;
    }

    if (_matchesAny(normalized, _memoryPhrases)) {
      return VoiceIntentClass.memories;
    }

    if (_matchesAny(normalized, _activityPhrases)) {
      return VoiceIntentClass.activity;
    }

    return VoiceIntentClass.unclear;
  }

  /// Lowercase, strip accents, collapse whitespace, drop punctuation noise.
  static String normalize(String? raw) {
    if (raw == null) {
      return '';
    }
    final lowered = raw.trim().toLowerCase();
    if (lowered.isEmpty) {
      return '';
    }
    final buf = StringBuffer();
    var prevSpace = false;
    for (final rune in lowered.runes) {
      final ch = String.fromCharCode(rune);
      final mapped = _accentFold[ch] ?? ch;
      if (_isLetterOrDigit(mapped)) {
        buf.write(mapped);
        prevSpace = false;
      } else if (!prevSpace) {
        buf.write(' ');
        prevSpace = true;
      }
    }
    return buf.toString().trim();
  }

  static bool _matchesAny(String normalized, List<String> phrases) {
    for (final phrase in phrases) {
      final needle = normalize(phrase);
      if (needle.isEmpty) {
        continue;
      }
      if (normalized == needle ||
          normalized.startsWith('$needle ') ||
          normalized.endsWith(' $needle') ||
          normalized.contains(' $needle ')) {
        return true;
      }
    }
    return false;
  }

  static bool _isLetterOrDigit(String ch) {
    if (ch.length != 1) {
      return false;
    }
    final code = ch.codeUnitAt(0);
    return (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
  }

  static const Map<String, String> _accentFold = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };

  // --- Explicit intent fixtures (fictional Spanish only) ---

  static const List<String> _safetyPhrases = <String>[
    'me duele el pecho',
    'dolor de pecho',
    'creo que tengo un ictus',
    'no puedo respirar',
    'llamad a emergencias',
    'llama a emergencias',
    'necesito una ambulancia',
    'urgencia medica',
    'urgencia médica',
    'me estoy muriendo',
    'sobre dosis',
    'sobredosis',
    'quiero suicidarme',
    'me quiero matar',
    'hay un incendio',
    'estoy en peligro',
    'me estan atacando',
    'me están atacando',
    'diagnostico medico',
    'diagnóstico médico',
    'que medicina tomo',
    'qué medicina tomo',
    'receta medica',
    'receta médica',
  ];

  static const List<String> _talkPhrases = <String>[
    'quiero hablar',
    'necesito hablar',
    'hablar con alguien',
    'hablar con mi familia',
    'llamar a alguien',
    'hacer una llamada',
    'quiero llamar',
    'puedo llamar',
    'telefono',
    'teléfono',
  ];

  static const List<String> _genericPhrases = <String>[
    'no se que hacer',
    'no sé qué hacer',
    'no se que elegir',
    'no sé qué elegir',
    'no se',
    'no sé',
    'ayudame a elegir',
    'ayúdame a elegir',
    'que elijo',
    'qué elijo',
    'no tengo claro',
    'estoy perdido',
    'estoy perdida',
    'sugiereme algo',
    'sugiéreme algo',
    'recomiendame algo',
    'recomiéndame algo',
  ];

  static const List<String> _routinePhrases = <String>[
    'mi dia',
    'mi día',
    'que tengo que hacer',
    'qué tengo que hacer',
    'que me toca ahora',
    'qué me toca ahora',
    'que toca ahora',
    'qué toca ahora',
    'mi rutina',
    'la rutina',
    'pasos de hoy',
    'el siguiente paso',
    'siguiente paso',
    'que pasa ahora',
    'qué pasa ahora',
    'agenda de hoy',
    'tareas de hoy',
  ];

  static const List<String> _memoryPhrases = <String>[
    'ver fotos',
    'ver las fotos',
    'fotos de la familia',
    'fotos familiares',
    'recuerdos',
    'ver recuerdos',
    'momentos familiares',
    'momentos de la familia',
    'fotografias',
    'fotografías',
    'album de fotos',
    'álbum de fotos',
    'ver a la familia',
  ];

  static const List<String> _activityPhrases = <String>[
    'pasatiempos',
    'pasatiempo',
    'quiero un pasatiempo',
    'algo para entretener',
    'entretenerme',
    'entretenimiento',
    'quiero hacer algo',
    'algo que hacer',
    'actividad',
    'actividades',
    'estoy aburrido',
    'estoy aburrida',
    'me aburro',
    'jugar un poco',
    'escuchar la radio',
    'hacer un puzzle',
    'hacer un rompecabezas',
  ];
}
