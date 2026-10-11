/// Memora shared UI primitives and Slice 4–7 presentation.
///
/// Dependency rule: may import `package:domain/` only among project packages.
/// Must not import `package:data/` or implement authorization policy.
library;

export 'src/apps/memora_feature_app.dart';
export 'src/demo/demo_ids.dart';
export 'src/demo/spanish_date_format.dart';
export 'src/experience_target.dart';
export 'src/family/family_memory_controller.dart';
export 'src/family/family_memory_page.dart';
export 'src/family/family_observation_controller.dart';
export 'src/family/family_observation_page.dart';
export 'src/family/family_routine_configure_page.dart';
export 'src/family/family_routine_controller.dart';
export 'src/help/help_about_page.dart';
export 'src/l10n/memora_copy.dart';
export 'src/navigation/feature_section.dart';
export 'src/navigation/feature_section_nav.dart';
export 'src/non_production_shell.dart';
export 'src/privacy/privacy_page.dart';
export 'src/privacy/privacy_presentation_controller.dart';
export 'src/sync/presentation_sync.dart';
export 'src/sync/sync_presentation_controller.dart';
export 'src/sync/sync_status_page.dart';
export 'src/theme/memora_theme.dart';
export 'src/user/user_approved_memories_page.dart';
export 'src/user/user_destination_scaffold.dart';
export 'src/user/user_home_destination.dart';
export 'src/user/user_home_grid.dart';
export 'src/user/user_memory_controller.dart';
export 'src/user/user_placeholder_page.dart';
export 'src/user/user_routine_controller.dart';
export 'src/user/user_routine_home.dart';
export 'src/widgets/demo_banner.dart';
export 'src/widgets/draft_text_field.dart';
export 'src/widgets/shell_scaffold.dart';
export 'src/widgets/sync_status_bar.dart';
