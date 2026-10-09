import 'synthetic_persona.dart';

/// Deterministic fictional personas authorized for Slice 1 shells and tests.
///
/// Names: Amparo Demo, Elena Demo, Familia Ejemplo. Not real people.
abstract final class SyntheticFixtures {
  static const SyntheticPersona amparoDemo = SyntheticPersona(
    displayName: 'Amparo Demo',
    roleLabel: 'Supported person (synthetic)',
  );

  static const SyntheticPersona elenaDemo = SyntheticPersona(
    displayName: 'Elena Demo',
    roleLabel: 'Primary caregiver (synthetic)',
  );

  static const SyntheticPersona familiaEjemplo = SyntheticPersona(
    displayName: 'Familia Ejemplo',
    roleLabel: 'Family space (synthetic)',
  );

  /// Stable ordered catalog for shells and boundary tests.
  static const List<SyntheticPersona> all = <SyntheticPersona>[
    amparoDemo,
    elenaDemo,
    familiaEjemplo,
  ];
}
