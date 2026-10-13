/// Whether this client shares a local demo sync authority with other processes.
///
/// Presentation-only: authorization and transport selection stay in app
/// composition / data adapters.
enum DemoDataScope {
  /// Private in-process store/transport — changes stay on this client.
  isolatedLocal,

  /// Loopback shared demo transport — fictional data only, no production.
  sharedLocalDemo,
}
