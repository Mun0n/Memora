/// Test-injectable deterministic random source for board generation.
///
/// Never depends on wall-clock sleeps. Same seed → same sequence.
final class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  /// Next non-negative int in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    // Minimal standard LCG (Numerical Recipes); fine for puzzles, not crypto.
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
