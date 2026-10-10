/// Monotonic concurrency token for offline aggregates.
///
/// Starts at `0` for a newly created local aggregate. Callers bump on each
/// accepted local mutation. Silent merges of concurrent versions are forbidden.
final class AggregateVersion {
  factory AggregateVersion(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'must be >= 0');
    }
    return AggregateVersion._(value);
  }

  const AggregateVersion._(this.value);

  /// Initial local version for a newly created aggregate.
  static const AggregateVersion initial = AggregateVersion._(0);

  final int value;

  AggregateVersion next() => AggregateVersion._(value + 1);

  bool isBefore(AggregateVersion other) => value < other.value;

  @override
  bool operator ==(Object other) =>
      other is AggregateVersion && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AggregateVersion($value)';
}
