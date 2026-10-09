/// A clearly labeled fictional persona for non-production shells and tests.
///
/// All Memora v0.1 fixtures are synthetic. Never use real personal or health data.
final class SyntheticPersona {
  const SyntheticPersona({required this.displayName, required this.roleLabel});

  /// Display name; must remain recognizably fictional (Demo / Ejemplo).
  final String displayName;

  /// Non-medical role label for shell copy only (not an authorization capability).
  final String roleLabel;

  /// Always true for committed fixtures; callers may rely on this marker.
  bool get isSynthetic => true;

  /// Plain-language marker for UI shells and reports.
  String get syntheticMarker => 'SYNTHETIC / NON-PRODUCTION';
}
