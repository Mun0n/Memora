/// Stable key that makes outbox enqueue idempotent across retries/restarts.
final class IdempotencyKey {
  factory IdempotencyKey(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'must be non-empty');
    }
    return IdempotencyKey._(value);
  }

  const IdempotencyKey._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is IdempotencyKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IdempotencyKey($value)';
}
