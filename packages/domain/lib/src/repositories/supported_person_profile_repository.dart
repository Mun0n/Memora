import '../identity/identifiers.dart';
import '../identity/supported_person_profile.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Local-first supported-person preferred-name profile port.
///
/// At most one live profile per [FamilySpaceId]. Writes must be immediately
/// readable and enqueue an outbox mutation.
abstract interface class SupportedPersonProfileRepository {
  Future<SupportedPersonProfile> save({
    required SupportedPersonProfile profile,
    required IdempotencyKey idempotencyKey,
  });

  Future<SupportedPersonProfile?> findById(SupportedPersonProfileId id);

  /// Live (non-tombstoned) profile for [familySpaceId], if any.
  Future<SupportedPersonProfile?> findForFamily(FamilySpaceId familySpaceId);

  Future<SupportedPersonProfile> softDelete({
    required SupportedPersonProfileId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
