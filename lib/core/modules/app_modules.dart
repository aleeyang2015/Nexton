/// The subscription modules the App sits behind (#61): what the company has
/// bought, from `/auth/me`'s `modules`. Hiding only stops staff from tapping
/// into a dead end; the server stays the gate (`403 MODULE_NOT_ACTIVE`).
/// Pure: the session-reading providers live in the auth feature
/// (`module_access_provider.dart`).
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
