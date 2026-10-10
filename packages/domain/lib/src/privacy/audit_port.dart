import '../identity/identifiers.dart';
import 'audit_record.dart';

/// Append-only audit history port (clients cannot erase).
abstract interface class AuditPort {
  Future<void> append(AuditRecord record);

  Future<List<AuditRecord>> listForFamily(FamilySpaceId familySpaceId);
}
