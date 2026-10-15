import 'package:domain/domain.dart';

/// Web/non-IO stub — durable file recovery requires `dart:io`.
final class FilePastimeSessionRecoveryStore
    implements PastimeSessionRecoveryPort {
  FilePastimeSessionRecoveryStore(String path) {
    throw UnsupportedError(
      'FilePastimeSessionRecoveryStore requires dart:io '
      '(path was $path). Use InMemoryPastimeSessionRecoveryStore on web.',
    );
  }

  /// API parity with the IO implementation (unused on stub).
  DateTime Function() now = () => DateTime.now().toUtc();

  @override
  Future<PastimeSessionRecoverySnapshot?> loadCurrent() async =>
      throw UnsupportedError(
        'FilePastimeSessionRecoveryStore requires dart:io',
      );

  @override
  Future<void> save(PastimeSessionRecoverySnapshot snapshot) async =>
      throw UnsupportedError(
        'FilePastimeSessionRecoveryStore requires dart:io',
      );

  @override
  Future<void> clear() async => throw UnsupportedError(
    'FilePastimeSessionRecoveryStore requires dart:io',
  );

  @override
  Future<void> clearIfMatches({
    required PastimeId pastimeId,
    String? experienceType,
    int? experienceSchemaVersion,
  }) async => throw UnsupportedError(
    'FilePastimeSessionRecoveryStore requires dart:io',
  );
}
