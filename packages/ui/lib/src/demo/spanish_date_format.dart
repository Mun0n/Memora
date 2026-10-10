/// Minimal Spanish civil date/time formatting (no `intl` dependency).
abstract final class SpanishDateFormat {
  static const List<String> _weekdays = <String>[
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const List<String> _months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String formatDate(DateTime local) {
    final weekday = _weekdays[local.weekday - 1];
    final month = _months[local.month - 1];
    return '$weekday, ${local.day} de $month de ${local.year}';
  }

  static String formatTime(DateTime local) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDateTime(DateTime local) {
    return '${formatDate(local)} · ${formatTime(local)}';
  }
}
