import '../../../core/modules/app_modules.dart';
import 'entities/user.dart';

/// What the user's company has bought (#61).
extension UserModules on User {
  bool get canUseCoreHr => AppModules.allows(modules, AppModules.coreHr);
  bool get canUsePayroll => AppModules.allows(modules, AppModules.payroll);
}
