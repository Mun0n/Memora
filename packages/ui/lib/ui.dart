/// Memora shared UI primitives for non-production shells.
///
/// Dependency rule: may import `package:domain/` only among project packages.
/// Must not import `package:data/`, authorize access, or implement product features.
library;

export 'src/experience_target.dart';
export 'src/non_production_shell.dart';
