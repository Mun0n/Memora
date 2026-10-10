/// Minimal sign-in/session composition boundary for later connection.
///
/// Credential **names** only — never embed URL/key values or service-role.
abstract final class RemoteCredentialNames {
  /// Environment/config name for a future Supabase project URL.
  static const String supabaseUrl = 'MEMORA_SUPABASE_URL';

  /// Environment/config name for a future anon (public) key.
  static const String supabaseAnonKey = 'MEMORA_SUPABASE_ANON_KEY';

  /// Forbidden in clients; documented so scanners and composition reject it.
  static const String serviceRoleKey = 'MEMORA_SUPABASE_SERVICE_ROLE_KEY';

  static const Set<String> injectableNames = <String>{
    supabaseUrl,
    supabaseAnonKey,
  };

  static const Set<String> forbiddenClientNames = <String>{serviceRoleKey};
}

/// Composition modes for apps. Demo mode needs zero remote configuration.
enum SessionCompositionMode {
  /// No session; signed-out shell.
  signedOut,

  /// Offline fictional demo — default for MVP review.
  demoOffline,

  /// Host credentials are expected via [RemoteCredentialNames] only.
  namedCredentialsConfigured,
}

/// Session composition descriptor. Safe to log (names only).
final class SessionBoundary {
  const SessionBoundary({
    required this.mode,
    this.urlEnvName,
    this.anonKeyEnvName,
  }) : assert(
         mode != SessionCompositionMode.namedCredentialsConfigured ||
             (urlEnvName != null && anonKeyEnvName != null),
         'named credentials mode requires env name slots',
       );

  final SessionCompositionMode mode;

  /// Config key name for URL when [mode] is namedCredentialsConfigured.
  final String? urlEnvName;

  /// Config key name for anon key when [mode] is namedCredentialsConfigured.
  final String? anonKeyEnvName;

  /// Default MVP composition: offline demo, no remote config.
  static const SessionBoundary demo = SessionBoundary(
    mode: SessionCompositionMode.demoOffline,
  );

  static const SessionBoundary signedOut = SessionBoundary(
    mode: SessionCompositionMode.signedOut,
  );

  /// Later connection seam — names only, no values.
  factory SessionBoundary.namedCredentials() {
    return const SessionBoundary(
      mode: SessionCompositionMode.namedCredentialsConfigured,
      urlEnvName: RemoteCredentialNames.supabaseUrl,
      anonKeyEnvName: RemoteCredentialNames.supabaseAnonKey,
    );
  }

  bool get isDemoOffline => mode == SessionCompositionMode.demoOffline;

  bool get requiresNetwork =>
      mode == SessionCompositionMode.namedCredentialsConfigured;
}
