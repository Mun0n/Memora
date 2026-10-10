/// Which Memora client shell is running. Labels are for humans, not auth.
enum ExperienceTarget {
  user(
    englishLabel: 'User',
    spanishLabel: 'Usuario',
    semanticsLabel: 'Memora User shell, non-production demonstration',
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
