import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';

/// Cached preferred-name presentation for the supported-person home greeting.
///
/// Missing or failed loads keep any prior cache, otherwise the safe fallback
/// greeting (`Hola`). Never exposes identifiers, role labels or technical
/// error strings on the home.
final class UserSupportedPersonProfileController extends ChangeNotifier {
  UserSupportedPersonProfileController({
    required this.actor,
    required SupportedPersonProfileRepository profiles,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    ConfigureSupportedPersonProfile? configure,
  }) : _configure = configure ?? ConfigureSupportedPersonProfile(profiles);

  final FamilyMembership actor;
  final ConfigureSupportedPersonProfile _configure;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  SupportedPersonProfile? profile;
  bool isRefreshingShared = false;
  bool sharedPullFailed = false;

  /// Optional quiet pull before presenting shared-demo greeting.
  Future<bool> Function()? quietRemotePull;

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  /// Safe home greeting — never null, ids, roles or technical errors.
  String get homeGreeting => SupportedPersonProfile.homeGreeting(profile);

  Future<void> load() async {
    try {
      final found = await _configure.findForFamily(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      profile = found;
    } catch (_) {
      // Keep any prior cache; if none, greeting falls back to Hola.
    }
    notifyListeners();
  }

  Future<void> refreshFromSharedRemote() async {
    if (!isSharedDemo) {
      await load();
      return;
    }
    final pull = quietRemotePull;
    isRefreshingShared = true;
    notifyListeners();
    var pullOk = true;
    if (pull != null) {
      try {
        pullOk = await pull();
      } catch (_) {
        pullOk = false;
      }
    }
    sharedPullFailed = !pullOk;
    isRefreshingShared = false;
    await load();
  }
}
