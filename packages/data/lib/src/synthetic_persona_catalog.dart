import 'package:domain/domain.dart';

/// Local-only catalog backed by domain synthetic fixtures.
///
/// Intentionally not a remote repository: Slice 1 forbids auth, Supabase,
/// migrations, sync engines and production credentials.
final class SyntheticPersonaCatalog {
  const SyntheticPersonaCatalog();

  /// Returns the deterministic fictional persona set from `domain`.
  List<SyntheticPersona> listPersonas() =>
      List<SyntheticPersona>.unmodifiable(SyntheticFixtures.all);

  /// Lookup by exact fictional display name; null when unknown.
  SyntheticPersona? findByDisplayName(String displayName) {
    for (final persona in SyntheticFixtures.all) {
      if (persona.displayName == displayName) {
        return persona;
      }
    }
    return null;
  }
}
