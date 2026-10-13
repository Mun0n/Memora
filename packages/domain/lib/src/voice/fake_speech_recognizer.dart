import 'speech_recognizer_port.dart';

/// Deterministic speech recognizer for tests and non-Android demo hosts.
///
/// Never opens a real microphone. Outcomes are scripted via [enqueue] /
/// [nextOutcomes]. Transcripts exist only on returned [SpeechRecognized]
/// instances — this fake does not persist, log or sync them.
final class FakeSpeechRecognizer implements SpeechRecognizerPort {
  FakeSpeechRecognizer({
    this.availability = SpeechRecognizerAvailability.availableOnDevice,
    this.currentPermission = SpeechPermissionStatus.notDetermined,
    List<SpeechListenOutcome>? nextOutcomes,
    this.grantOnRequest = true,
  }) : _queue = List<SpeechListenOutcome>.of(
         nextOutcomes ?? const <SpeechListenOutcome>[],
       );

  SpeechRecognizerAvailability availability;
  SpeechPermissionStatus currentPermission;
  final List<SpeechListenOutcome> _queue;

  /// When true, [requestPermission] moves notDetermined → granted.
  /// When false, moves notDetermined → denied (unless already permanent).
  bool grantOnRequest;

  int checkAvailabilityCount = 0;
  int permissionStatusCount = 0;
  int requestPermissionCount = 0;
  int listenCount = 0;
  int cancelCount = 0;
  int releaseCount = 0;

  bool _listening = false;

  /// Optional override applied on the next [listen] before the queue.
  SpeechListenOutcome? forceNextOutcome;

  void enqueue(SpeechListenOutcome outcome) => _queue.add(outcome);

  void enqueueAll(Iterable<SpeechListenOutcome> outcomes) =>
      _queue.addAll(outcomes);

  void clearQueue() => _queue.clear();

  @override
  bool get isListening => _listening;

  @override
  Future<SpeechRecognizerAvailability> checkAvailability() async {
    checkAvailabilityCount += 1;
    return availability;
  }

  @override
  Future<SpeechPermissionStatus> permissionStatus() async {
    permissionStatusCount += 1;
    return currentPermission;
  }

  @override
  Future<SpeechPermissionStatus> requestPermission() async {
    requestPermissionCount += 1;
    if (currentPermission == SpeechPermissionStatus.permanentlyDenied) {
      return currentPermission;
    }
    if (currentPermission == SpeechPermissionStatus.granted) {
      return currentPermission;
    }
    currentPermission = grantOnRequest
        ? SpeechPermissionStatus.granted
        : SpeechPermissionStatus.denied;
    return currentPermission;
  }

  @override
  Future<SpeechListenOutcome> listen({Duration? timeout}) async {
    listenCount += 1;

    if (availability != SpeechRecognizerAvailability.availableOnDevice) {
      return SpeechUnavailableOutcome(availability: availability);
    }

    if (currentPermission == SpeechPermissionStatus.denied) {
      return const SpeechPermissionDeniedOutcome();
    }
    if (currentPermission == SpeechPermissionStatus.permanentlyDenied) {
      return const SpeechPermissionDeniedOutcome(permanent: true);
    }
    if (currentPermission == SpeechPermissionStatus.notDetermined) {
      return const SpeechPermissionDeniedOutcome();
    }

    _listening = true;
    try {
      final forced = forceNextOutcome;
      forceNextOutcome = null;
      if (forced != null) {
        return forced;
      }
      if (_queue.isNotEmpty) {
        return _queue.removeAt(0);
      }
      // Default calm timeout when tests forget to enqueue — never invent speech.
      return const SpeechTimeout();
    } finally {
      _listening = false;
    }
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    _listening = false;
  }

  @override
  Future<void> release() async {
    releaseCount += 1;
    _listening = false;
  }
}
