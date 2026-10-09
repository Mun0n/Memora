/// Which Memora client shell is running. Labels are for humans, not auth.
enum ExperienceTarget {
  tablet(
    englishLabel: 'Tablet',
    spanishLabel: 'Tableta',
    semanticsLabel: 'Memora Tablet shell, non-production demonstration',
  ),
  caregiver(
    englishLabel: 'Caregiver',
    spanishLabel: 'Cuidadora',
    semanticsLabel: 'Memora Caregiver shell, non-production demonstration',
  ),
  familyWeb(
    englishLabel: 'Family Web',
    spanishLabel: 'Web familiar',
    semanticsLabel: 'Memora Family Web shell, non-production demonstration',
  );

  const ExperienceTarget({
    required this.englishLabel,
    required this.spanishLabel,
    required this.semanticsLabel,
  });

  final String englishLabel;
  final String spanishLabel;
  final String semanticsLabel;
}
