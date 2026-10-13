/// Opaque aggregate identifiers for offline content and observations.
library;

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void _assertUuid(String raw, String label) {
  if (!_uuidPattern.hasMatch(raw)) {
    throw FormatException('Invalid $label UUID: $raw');
  }
}

/// Opaque routine identifier (UUID string).
final class RoutineId {
  factory RoutineId(String raw) {
    _assertUuid(raw, 'RoutineId');
    return RoutineId._(raw.toLowerCase());
  }

  const RoutineId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is RoutineId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RoutineId($value)';
}

/// Opaque reminder identifier (UUID string).
final class ReminderId {
  factory ReminderId(String raw) {
    _assertUuid(raw, 'ReminderId');
    return ReminderId._(raw.toLowerCase());
  }

  const ReminderId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is ReminderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReminderId($value)';
}

/// Opaque memory identifier (UUID string).
final class MemoryId {
  factory MemoryId(String raw) {
    _assertUuid(raw, 'MemoryId');
    return MemoryId._(raw.toLowerCase());
  }

  const MemoryId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is MemoryId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MemoryId($value)';
}

/// Opaque observation identifier (UUID string) for weight and blood pressure.
final class ObservationId {
  factory ObservationId(String raw) {
    _assertUuid(raw, 'ObservationId');
    return ObservationId._(raw.toLowerCase());
  }

  const ObservationId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ObservationId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ObservationId($value)';
}

/// Opaque pastime identifier (UUID string).
final class PastimeId {
  factory PastimeId(String raw) {
    _assertUuid(raw, 'PastimeId');
    return PastimeId._(raw.toLowerCase());
  }

  const PastimeId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is PastimeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PastimeId($value)';
}

/// Opaque conversation-topic identifier (UUID string).
final class ConversationTopicId {
  factory ConversationTopicId(String raw) {
    _assertUuid(raw, 'ConversationTopicId');
    return ConversationTopicId._(raw.toLowerCase());
  }

  const ConversationTopicId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ConversationTopicId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ConversationTopicId($value)';
}

/// Opaque routine day-progress identifier (UUID string).
final class RoutineProgressId {
  factory RoutineProgressId(String raw) {
    _assertUuid(raw, 'RoutineProgressId');
    return RoutineProgressId._(raw.toLowerCase());
  }

  const RoutineProgressId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is RoutineProgressId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RoutineProgressId($value)';
}
