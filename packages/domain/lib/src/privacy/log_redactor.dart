/// Redacts content, health values, tokens and media URLs from log strings.
///
/// Used by sync/debug paths. Prefer structured labels over payloads.
abstract final class LogRedactor {
  static final RegExp _bearer = RegExp(
    r'(bearer\s+)[a-z0-9._\-]+',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+',
  );
  static final RegExp _mediaUrl = RegExp(
    r'(https?://\S+|supabase(\.co)?/\S+|storage/v1/\S+)',
    caseSensitive: false,
  );
  static final RegExp _familyMediaPath = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/\S+',
    caseSensitive: false,
  );
  static final RegExp _kg = RegExp(
    r'(\bkilograms?\b|\bkg\b)\s*[:=]?\s*-?\d+(\.\d+)?',
    caseSensitive: false,
  );
  static final RegExp _mmHg = RegExp(
    r'(\bsystolic\b|\bdiastolic\b|\bmmHg\b)\s*[:=]?\s*-?\d+',
    caseSensitive: false,
  );
  static final RegExp _bpPair = RegExp(r'\b\d{2,3}\s*/\s*\d{2,3}\b');
  static final RegExp _tokenKey = RegExp(
    r'(api[_-]?key|access[_-]?token|refresh[_-]?token|service[_-]?role|anon[_-]?key)\s*[:=]\s*\S+',
    caseSensitive: false,
  );
  static final RegExp _caption = RegExp(
    r'(caption|title|instruction)\s*[:=]\s*.+',
    caseSensitive: false,
  );

  /// Returns a redacted copy safe for logs.
  static String redact(String input) {
    var out = input;
    out = out.replaceAllMapped(_bearer, (m) => '${m[1]}[REDACTED]');
    out = out.replaceAll(_jwt, '[REDACTED_TOKEN]');
    out = out.replaceAllMapped(_tokenKey, (m) {
      final key = m.group(1)!;
      return '$key=[REDACTED]';
    });
    out = out.replaceAll(_mediaUrl, '[REDACTED_MEDIA_URL]');
    out = out.replaceAll(_familyMediaPath, '[REDACTED_MEDIA_PATH]');
    out = out.replaceAllMapped(_kg, (m) => '${m[1]}=[REDACTED_HEALTH]');
    out = out.replaceAllMapped(_mmHg, (m) => '${m[1]}=[REDACTED_HEALTH]');
    out = out.replaceAll(_bpPair, '[REDACTED_HEALTH]');
    out = out.replaceAllMapped(_caption, (m) => '${m[1]}=[REDACTED_CONTENT]');
    return out;
  }

  /// Redacts string values in a context map; non-strings passed through.
  static Map<String, Object?> redactContext(Map<String, Object?> context) {
    final out = <String, Object?>{};
    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (value is String) {
        if (_sensitiveKey(key)) {
          out[entry.key] = '[REDACTED]';
        } else {
          out[entry.key] = redact(value);
        }
      } else if (value is num && _healthKey(key)) {
        out[entry.key] = '[REDACTED_HEALTH]';
      } else {
        out[entry.key] = value;
      }
    }
    return Map<String, Object?>.unmodifiable(out);
  }

  static bool _sensitiveKey(String key) {
    return key.contains('token') ||
        key.contains('password') ||
        key.contains('secret') ||
        key.contains('authorization') ||
        key.contains('url') ||
        key.contains('path') ||
        key.contains('checksum') ||
        key.contains('caption') ||
        key.contains('title') ||
        key.contains('instruction');
  }

  static bool _healthKey(String key) {
    return key.contains('kilogram') ||
        key.contains('weight') ||
        key.contains('systolic') ||
        key.contains('diastolic') ||
        key.contains('mmhg') ||
        key == 'kg';
  }
}
