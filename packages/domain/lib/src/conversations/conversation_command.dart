/// Minimal fixed command vocabulary for conversation control.
///
/// Ordinary answers are not commands and do not branch content.
enum ConversationCommand { repeat, changeTopic, finish, noMeAcuerdo }

/// Pure Spanish-first matcher for the fixed control vocabulary.
abstract final class ConversationCommandMatcher {
  static ConversationCommand? classify(String? textInMemory) {
    final normalized = _normalize(textInMemory);
    if (normalized.isEmpty) {
      return null;
    }
    if (_matches(normalized, _repeat)) {
      return ConversationCommand.repeat;
    }
    if (_matches(normalized, _changeTopic)) {
      return ConversationCommand.changeTopic;
    }
    if (_matches(normalized, _finish)) {
      return ConversationCommand.finish;
    }
    if (_matches(normalized, _noMeAcuerdo)) {
      return ConversationCommand.noMeAcuerdo;
    }
    return null;
  }

  static const List<String> _repeat = <String>[
    'repetir',
    'repite',
    'otra vez',
    'de nuevo',
  ];

  static const List<String> _changeTopic = <String>[
    'cambiar de tema',
    'otro tema',
    'cambia de tema',
    'cambiar tema',
  ];

  static const List<String> _finish = <String>[
    'terminar',
    'acabar',
    'salir',
    'ya esta',
  ];

  static const List<String> _noMeAcuerdo = <String>[
    'no me acuerdo',
    'no recuerdo',
    'no me acuerdo de nada',
  ];

  static bool _matches(String normalized, List<String> phrases) {
    for (final phrase in phrases) {
      final p = _normalize(phrase);
      if (normalized == p || normalized.contains(p)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String? raw) {
    if (raw == null) {
      return '';
    }
    var s = raw.trim().toLowerCase();
    const accents = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(accents[ch] ?? ch);
    }
    s = buffer.toString();
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}
