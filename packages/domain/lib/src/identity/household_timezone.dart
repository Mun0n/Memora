/// Required household IANA timezone string with deterministic structure checks.
///
/// Validates shape only — no network lookup or timezone database dependency.
final class HouseholdTimezone {
  factory HouseholdTimezone(String raw) {
    final trimmed = raw.trim();
    if (!_isValidStructure(trimmed)) {
      throw FormatException('Invalid IANA timezone structure: $raw');
    }
    return HouseholdTimezone._(trimmed);
  }

  const HouseholdTimezone._(this.value);

  final String value;

  /// Same structural rule as the SQL CHECK on `family_spaces.household_timezone`.
  static final RegExp structurePattern = RegExp(
    r'^(?:UTC|[A-Za-z]+(?:[_-][A-Za-z]+)*(?:/[A-Za-z0-9]+(?:[_-][A-Za-z0-9]+)*)+)$',
  );

  static bool _isValidStructure(String value) =>
      value.isNotEmpty && structurePattern.hasMatch(value);

  @override
  bool operator ==(Object other) =>
      other is HouseholdTimezone && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'HouseholdTimezone($value)';
}
