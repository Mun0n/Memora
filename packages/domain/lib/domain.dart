/// Memora domain layer: pure Dart entities, value objects and synthetic fixtures.
///
/// Dependency rule: this package must not import Flutter, Supabase, or other
/// project packages (`data`, `ui`, apps).
library;

export 'src/identity/family_access_policy.dart';
export 'src/identity/family_capability.dart';
export 'src/identity/family_membership.dart';
export 'src/identity/family_role.dart';
export 'src/identity/family_space.dart';
export 'src/identity/household_timezone.dart';
export 'src/identity/identifiers.dart';
export 'src/identity/identity_fixtures.dart';
export 'src/identity/membership_status.dart';
export 'src/synthetic_fixtures.dart';
export 'src/synthetic_persona.dart';
