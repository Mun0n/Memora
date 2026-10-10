import 'household_timezone.dart';
import 'identifiers.dart';

/// Immutable family-space aggregate root for identity contracts.
final class FamilySpace {
  FamilySpace({
    required this.id,
    required this.displayName,
    required this.householdTimezone,
  }) {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'must be non-empty',
      );
    }
  }

  final FamilySpaceId id;
  final String displayName;
  final HouseholdTimezone householdTimezone;
}
