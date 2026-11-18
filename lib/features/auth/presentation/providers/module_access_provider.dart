import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/modules/app_modules.dart';
import 'auth_session_notifier.dart';

/// The signed-in company's modules (#61), read on their own: a gate does not
/// rebuild on other session changes. Empty when no one is signed in.
final activeModulesProvider = Provider<List<String>>(
  (ref) =>
      ref.watch(
        authSessionProvider.select((s) => s.valueOrNull?.user?.modules),
      ) ??
      const [],
);

/// Whether the company has [module] (with what it depends on). A yes/no, so
/// a screen rebuilds only when the answer changes.
final hasModuleProvider = Provider.family<bool, String>(
  (ref, module) => AppModules.allows(ref.watch(activeModulesProvider), module),
);
