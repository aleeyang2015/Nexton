import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/modules/app_modules.dart';
import 'package:next_on/features/auth/domain/user_modules.dart';
import 'package:next_on/features/auth/presentation/providers/module_access_provider.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';

import '../../support/auth_test_doubles.dart';

/// What the company has bought (#61).
void main() {
  for (final (label, modules, coreHr, payroll)
      in <(String, List<String>, bool, bool)>[
        ('Core HR and Payroll', ['core_hr', 'payroll'], true, true),
        ('Core HR only', ['core_hr'], true, false),
        // Payroll depends on Core HR: alone it opens nothing.
        ('Payroll alone', ['payroll'], false, false),
        ('nothing (no active subscription)', [], false, false),
        ('only modules the App does not use', ['recruitment'], false, false),
      ]) {
    test(label, () {
      final user = testUser(modules: modules);
      expect(user.canUseCoreHr, coreHr);
      expect(user.canUsePayroll, payroll);
      expect(AppModules.allows(modules, AppModules.coreHr), coreHr);
      expect(AppModules.allows(modules, AppModules.payroll), payroll);
    });
  }

  test('no one signed in: no module', () async {
    final container = ProviderContainer(
      overrides: [authSessionProvider.overrideWith(_SignedOut.new)],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    expect(container.read(activeModulesProvider), isEmpty);
    expect(container.read(hasModuleProvider(AppModules.coreHr)), isFalse);
  });

  test('signed in: the session user\'s modules', () async {
    final container = ProviderContainer(
      overrides: [authSessionProvider.overrideWith(_SignedIn.new)],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    expect(container.read(hasModuleProvider(AppModules.coreHr)), isTrue);
    expect(container.read(hasModuleProvider(AppModules.payroll)), isFalse);
  });
}

class _SignedOut extends AuthSessionNotifier {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}

class _SignedIn extends AuthSessionNotifier {
  @override
  Future<AuthSession> build() async =>
      AuthSession.signedIn(testUser(modules: const ['core_hr']));
}
