/// Memora data layer: transport-neutral DTOs and local catalogs.
///
/// Dependency rule: may depend on `domain` only among project packages.
/// No Supabase client, network repository, sync queue or credentials in Slice 2.
library;

export 'src/identity/family_membership_dto.dart';
export 'src/identity/family_space_dto.dart';
export 'src/synthetic_persona_catalog.dart';
