import '../../offline/offline_identifiers.dart';

/// Minimum device-local recovery snapshot for an unfinished playable session.
///
/// Never synced, audited, analysed or shown to caregivers. Contains no free
/// text, taps, mistakes, duration or completion counts.
final class PastimeSessionRecoverySnapshot {
  static const Duration maxRetention = Duration(hours: 24);

  PastimeSessionRecoverySnapshot({
    required this.pastimeId,
    required this.experienceType,
    required this.experienceSchemaVersion,
    required this.seed,
    required this.boardState,
    required this.updatedAt,
  }) {
    if (experienceType.trim().isEmpty) {
      throw ArgumentError.value(experienceType, 'experienceType');
    }
    if (experienceSchemaVersion < 1) {
      throw ArgumentError.value(
        experienceSchemaVersion,
        'experienceSchemaVersion',
      );
    }
  }

  final PastimeId pastimeId;
  final String experienceType;
  final int experienceSchemaVersion;
  final int seed;

  /// Engine-owned board map (no free-text instruction/title).
  final Map<String, Object?> boardState;
  final DateTime updatedAt;

  bool isExpiredAt(DateTime now) =>
      now.toUtc().difference(updatedAt.toUtc()) > maxRetention;

  bool matchesDefinition({
    required String experienceType,
    required int experienceSchemaVersion,
  }) {
    return this.experienceType == experienceType &&
        this.experienceSchemaVersion == experienceSchemaVersion;
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'pastimeId': pastimeId.value,
    'experienceType': experienceType,
    'experienceSchemaVersion': experienceSchemaVersion,
    'seed': seed,
    'boardState': boardState,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static PastimeSessionRecoverySnapshot? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    try {
      final map = Map<String, Object?>.from(raw);
      final boardRaw = map['boardState'];
      if (boardRaw is! Map) {
        return null;
      }
      final updatedRaw = map['updatedAt'];
      if (updatedRaw is! String) {
        return null;
      }
      return PastimeSessionRecoverySnapshot(
        pastimeId: PastimeId(map['pastimeId']! as String),
        experienceType: map['experienceType']! as String,
        experienceSchemaVersion: map['experienceSchemaVersion']! as int,
        seed: map['seed']! as int,
        boardState: Map<String, Object?>.from(boardRaw),
        updatedAt: DateTime.parse(updatedRaw).toUtc(),
      );
    } on Object {
      return null;
    }
  }
}

/// Device-local recovery port — never an outbox / sync aggregate.
abstract class PastimeSessionRecoveryPort {
  /// At most one unfinished session per device.
  Future<PastimeSessionRecoverySnapshot?> loadCurrent();

  Future<void> save(PastimeSessionRecoverySnapshot snapshot);

  Future<void> clear();

  /// Removes snapshot when pastime is deleted or definition version changes.
  Future<void> clearIfMatches({
    required PastimeId pastimeId,
    String? experienceType,
    int? experienceSchemaVersion,
  });
}
