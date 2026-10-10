/// Membership lifecycle status. Only [active] grants capabilities.
enum MembershipStatus {
  active('active'),
  invited('invited'),
  revoked('revoked');

  const MembershipStatus(this.wireName);

  /// Canonical wire/SQL name.
  final String wireName;

  static MembershipStatus parse(String raw) {
    for (final status in MembershipStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown MembershipStatus: $raw');
  }
}
