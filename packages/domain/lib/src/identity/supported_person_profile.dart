import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'identifiers.dart';

/// Family-scoped supported-person preferred-name profile (one per family space).
///
/// Attached to the active supported-person profile, not a device installation.
/// Preferred names are personal data — never log the raw value.
final class SupportedPersonProfile {
  static const int minPreferredNameLength = 1;
  static const int maxPreferredNameLength = 40;

  SupportedPersonProfile({
    required this.id,
    required this.familySpaceId,
    required String preferredName,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) : preferredName = normalizePreferredName(preferredName);

  final SupportedPersonProfileId id;
  final FamilySpaceId familySpaceId;

  /// Trimmed preferred display name (1–40 Unicode scalars, no control chars).
  final String preferredName;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Safe home greeting: `Hola, <name>` or exactly `Hola` when missing/deleted.
  static String homeGreeting(SupportedPersonProfile? profile) {
    if (profile == null || profile.isDeleted) {
      return 'Hola';
    }
    return 'Hola, ${profile.preferredName}';
  }

  /// Validates and trims [raw]. Throws [ArgumentError] on invalid input.
  static String normalizePreferredName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        raw,
        'preferredName',
        'must be non-empty after trim',
      );
    }
    final scalarLength = trimmed.runes.length;
    if (scalarLength < minPreferredNameLength ||
        scalarLength > maxPreferredNameLength) {
      throw ArgumentError.value(
        raw,
        'preferredName',
        'must be $minPreferredNameLength–$maxPreferredNameLength '
            'Unicode characters after trim',
      );
    }
    for (final rune in trimmed.runes) {
      if (_isControlRune(rune)) {
        throw ArgumentError.value(
          raw,
          'preferredName',
          'must not contain control characters',
        );
      }
    }
    return trimmed;
  }

  /// Returns whether [raw] is a valid preferred name without throwing.
  static bool isValidPreferredName(String raw) {
    try {
      normalizePreferredName(raw);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static bool _isControlRune(int rune) {
    return rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F);
  }

  SupportedPersonProfile copyWith({
    String? preferredName,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return SupportedPersonProfile(
      id: id,
      familySpaceId: familySpaceId,
      preferredName: preferredName ?? this.preferredName,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
