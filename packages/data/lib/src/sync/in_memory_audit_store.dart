import 'package:domain/domain.dart';

/// Append-only in-memory audit history (clients cannot erase).
final class InMemoryAuditStore implements AuditPort {
  final List<AuditRecord> _records = <AuditRecord>[];

  @override
  Future<void> append(AuditRecord record) async {
    _records.add(record);
  }

  @override
  Future<List<AuditRecord>> listForFamily(FamilySpaceId familySpaceId) async {
    return _records
        .where((r) => r.familySpaceId == familySpaceId)
        .toList(growable: false);
  }
}
