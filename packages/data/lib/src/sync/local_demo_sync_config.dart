/// Local fictional-only demo sync bind defaults.
///
/// No hosted Supabase, credentials or production endpoints. Clients opt in via
/// [urlEnvironmentKey] / `--dart-define` or an explicit base URL.
abstract final class LocalDemoSyncConfig {
  static const String defaultHost = '127.0.0.1';
  static const int defaultPort = 17808;
  static const String defaultBaseUrl = 'http://127.0.0.1:17808';

  /// Process env / `--dart-define` key for the shared demo transport URL.
  static const String urlEnvironmentKey = 'MEMORA_LOCAL_DEMO_SYNC_URL';

  /// Process env key for the durable authority snapshot path.
  static const String snapshotEnvironmentKey =
      'MEMORA_LOCAL_DEMO_SYNC_SNAPSHOT';

  /// Default snapshot filename under [defaultSnapshotDirectoryName].
  static const String defaultSnapshotFileName = 'authority_snapshot.json';

  /// Directory created beside the server working directory (`packages/data`).
  static const String defaultSnapshotDirectoryName = '.local_demo_sync';

  /// Compile-time value from `--dart-define=MEMORA_LOCAL_DEMO_SYNC_URL=...`.
  static const String dartDefineUrl = String.fromEnvironment(urlEnvironmentKey);

  /// Reserved fictional family spaces accepted by the local demo server.
  static const Set<String> allowedFamilySpaceIds = {
    '01932f00-0002-7000-8000-0000000000a1', // Familia Ejemplo
    '01932f00-0002-7000-8000-0000000000b2', // Casa Demo B
  };

  /// Returns a trimmed URL when shared demo transport is configured.
  static String? resolveConfiguredUrl({String? explicit}) {
    final fromExplicit = explicit?.trim();
    if (fromExplicit != null && fromExplicit.isNotEmpty) {
      return fromExplicit;
    }
    final fromDefine = dartDefineUrl.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return null;
  }

  static bool isAllowedFamilySpaceId(String familySpaceId) =>
      allowedFamilySpaceIds.contains(familySpaceId.trim());
}
