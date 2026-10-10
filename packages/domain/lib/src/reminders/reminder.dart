import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'quiet_hours.dart';

/// Timed convenience reminder aggregate. Local-first; no delivery transport.
///
/// Reminders are caregiver-configured convenience prompts only. They are never
/// emergency coverage, medical alerting or guaranteed notification delivery.
final class Reminder {
  Reminder({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required this.scheduledAt,
    required this.version,
    required this.syncState,
    this.quietHours,
    this.tombstone,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must be non-empty');
    }
  }

  final ReminderId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final DateTime scheduledAt;

  /// Optional quiet-hours window that suppresses convenience prompts.
  final QuietHours? quietHours;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Whether a convenience prompt at [localInstant] is suppressed by quiet hours.
  ///
  /// [localInstant] must already be household-local civil time. No transport.
  bool isConveniencePromptSuppressed(DateTime localInstant) {
    final window = quietHours;
    if (window == null) {
      return false;
    }
    return window.containsLocalDateTime(localInstant);
  }

  Reminder copyWith({
    String? title,
    DateTime? scheduledAt,
    QuietHours? quietHours,
    bool clearQuietHours = false,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return Reminder(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      quietHours: clearQuietHours ? null : (quietHours ?? this.quietHours),
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
