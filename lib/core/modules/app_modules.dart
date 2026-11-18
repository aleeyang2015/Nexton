import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_session_notifier.dart';

/// The subscription modules the App sits behind (#61): what the company has
/// bought, from `/auth/me`'s `modules`. Hiding only stops staff from tapping
/// into a dead end; the server stays the gate (`403 MODULE_NOT_ACTIVE`).
abstract final class AppModules {
  /// The profile, clock in/out and its history, leave, OT, "forgot to
  /// scan", off-site, Approvals, personal info, the photo.
  static const String coreHr = 'core_hr';

  /// The salary list and payslips. Depends on Core HR.
  static const String payroll = 'payroll';

  /// Whether [modules] holds [module], with what it depends on: Payroll
  /// needs Core HR. An empty list holds nothing (no active subscription).
  static bool allows(List<String> modules, String module) => switch (module) {
    payroll => modules.contains(payroll) && modules.contains(coreHr),
    _ => modules.contains(module),
  };
}

extension UserModules on User {
  bool get canUseCoreHr => AppModules.allows(modules, AppModules.coreHr);
  bool get canUsePayroll => AppModules.allows(modules, AppModules.payroll);
}

/// The signed-in company's modules, read on their own: a screen that gates
/// on them does not rebuild on other session changes. Empty when no one is
/// signed in.
final activeModulesProvider = Provider<List<String>>(
  (ref) =>
      ref.watch(
        authSessionProvider.select((s) => s.valueOrNull?.user?.modules),
      ) ??
      const [],
);

/// Whether the company has [module] (with what it depends on).
final hasModuleProvider = Provider.family<bool, String>(
  (ref, module) => AppModules.allows(ref.watch(activeModulesProvider), module),
);
