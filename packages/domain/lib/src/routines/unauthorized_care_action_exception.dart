/// Thrown when a membership lacks role authority for a care/progress action.
final class UnauthorizedCareActionException implements Exception {
  UnauthorizedCareActionException(this.message);

  final String message;

  @override
  String toString() => 'UnauthorizedCareActionException: $message';
}
