import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/app.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/session_end_reason.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/pages/login_page.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:next_on/features/auth/presentation/widgets/login_email_field.dart';
import 'package:next_on/features/change_password/presentation/pages/change_password_page.dart';
import 'package:next_on/features/home/presentation/pages/home_page.dart';

import '../support/attendance_test_doubles.dart';
import '../support/auth_test_doubles.dart';
import '../support/test_asset_bundle.dart';

/// Drives the real `App`, the real router and the real notifiers, with only
/// the repository faked — so the redirect rules are exercised end to end.
void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  /// The App's clock. A test that waits on a timer points it at the test
  /// binding's clock, so the time moves with `tester.pump`.
  late DateTime Function() now;

  setUp(() {
    repository = FakeAuthRepository();
    now = DateTime.now;
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now()),
        // The home screen loads today's attendance as soon as it is shown;
        // without this it would reach for the real network stack.
        attendanceRepositoryProvider.overrideWithValue(
          FakeAttendanceRepository(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    repository.sessionExpired.close();
  });

  Future<void> launch(WidgetTester tester) async {
    // A phone-sized viewport; the default 800x600 pushes the auth forms off
    // screen and makes taps miss.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: const App(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(LoginEmailField),
        matching: find.byType(TextField),
      ),
      'somphone.vilaysone@nexton.la',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AuthPasswordField),
        matching: find.byType(TextField),
      ),
      'password1',
    );
    await tester.pump();

    final submit = find.text('ເຂົ້າສູ່ລະບົບ').last;
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-out cold start lands on the login screen', (
    tester,
  ) async {
    await launch(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('a restored session goes straight to the app', (tester) async {
    repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('a cold start owing a password change opens the change screen', (
    tester,
  ) async {
    repository.restoreResult = Result.success(
      AuthSession.signedIn(testUser(), mustChangePassword: true),
    );

    await launch(tester);

    // An app restart is not a way around the requirement.
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('logging in normally reaches the app', (tester) async {
    repository.loginResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);
    await signIn(tester);

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('must_change_password diverts to the change screen and cannot '
      'be routed around', (tester) async {
    repository.loginResult = Result.success(
      AuthSession.signedIn(testUser(), mustChangePassword: true),
    );

    await launch(tester);
    await signIn(tester);

    expect(find.byType(ChangePasswordPage), findsOneWidget);

    // Navigating anywhere else bounces straight back.
    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    container.read(appRouterProvider).go('/some/deep/link');
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    container.read(appRouterProvider).go(AppRoutes.login);
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('changing the password releases the user into the app', (
    tester,
  ) async {
    repository.loginResult = Result.success(
      AuthSession.signedIn(testUser(), mustChangePassword: true),
    );

    await launch(tester);
    await signIn(tester);
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    // The App signs in again after the change; the server no longer asks for
    // one.
    repository.loginResult = Result.success(AuthSession.signedIn(testUser()));

    final fields = find.descendant(
      of: find.byType(AuthPasswordField),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'current-pass');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tester.pump();

    await tester.ensureVisible(find.text('ບັນທຶກລະຫັດຜ່ານ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ບັນທຶກລະຫັດຜ່ານ'));
    await tester.pumpAndSettle();

    expect(repository.changePasswordCalls, 1);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsNothing);
  });

  testWidgets('a signed-in employee can change their password any time',
      (tester) async {
    repository
      ..restoreResult = Result.success(AuthSession.signedIn(testUser()))
      ..loginResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);
    expect(find.byType(HomePage), findsOneWidget);

    container.read(appRouterProvider).go(AppRoutes.changePassword);
    await tester.pumpAndSettle();

    // Reachable, and presented as a voluntary change rather than a demand.
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.text('ຕັ້ງລະຫັດຜ່ານໃໝ່ສຳລັບບັນຊີຂອງທ່ານ'), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(AuthPasswordField),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'current-pass');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'new-password');
    await tester.pump();

    await tester.ensureVisible(find.text('ບັນທຶກລະຫັດຜ່ານ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ບັນທຶກລະຫັດຜ່ານ'));
    await tester.pumpAndSettle();

    expect(repository.changePasswordCalls, 1);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('a throttled login turns the button off and says how many '
      'minutes are left', (tester) async {
    repository.loginResult = const Result.failure(
      Failure.network(
        message: 'Too many attempts',
        statusCode: 429,
        errorCode: 'TOO_MANY_LOGIN_ATTEMPTS',
        retryAfter: Duration(seconds: 600),
      ),
    );
    now = tester.binding.clock.now;

    await launch(tester);
    await signIn(tester);

    expect(
      find.text('ພະຍາຍາມຫຼາຍເກີນໄປ. ລອງໃໝ່ໄດ້ໃນອີກ 10 ນາທີ.'),
      findsOneWidget,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    // What was typed is still there.
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(AuthPasswordField),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      isNotEmpty,
    );
    expect(repository.loginCalls, 1);

    // The line follows the clock, and the button comes back on its own.
    await tester.pump(const Duration(minutes: 1));
    expect(
      find.text('ພະຍາຍາມຫຼາຍເກີນໄປ. ລອງໃໝ່ໄດ້ໃນອີກ 9 ນາທີ.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(minutes: 9));
    await tester.pump();
    expect(find.textContaining('ພະຍາຍາມຫຼາຍເກີນໄປ'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a wait that ran out while the phone slept ends when the App '
      'comes back', (tester) async {
    repository.loginResult = const Result.failure(
      Failure.network(
        message: 'Too many attempts',
        statusCode: 429,
        errorCode: 'TOO_MANY_LOGIN_ATTEMPTS',
        retryAfter: Duration(seconds: 600),
      ),
    );
    var asleepFor = Duration.zero;
    now = () => tester.binding.clock.now().add(asleepFor);

    await launch(tester);
    await signIn(tester);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    // No timer runs while the phone sleeps; only the clock moves.
    asleepFor = const Duration(minutes: 30);
    for (final lifecycle in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
    }
    await tester.pump();

    expect(find.textContaining('ພະຍາຍາມຫຼາຍເກີນໄປ'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('an unrecoverable 401 drops the user back to login', (
    tester,
  ) async {
    repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);
    expect(find.byType(HomePage), findsOneWidget);

    repository.sessionExpired.add(SessionEndReason.expired);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('a disabled account is told why on the login screen, once', (
    tester,
  ) async {
    repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);
    expect(find.byType(HomePage), findsOneWidget);

    repository.sessionExpired.add(SessionEndReason.accountDisabled);
    await tester.pumpAndSettle();

    const reason = 'ບັນຊີຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ຜູ້ດູແລລະບົບ.';
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text(reason), findsOneWidget);
    // Said, then forgotten: nothing is left to repeat it.
    expect(
      container.read(authSessionProvider).requireValue.endReason,
      isNull,
    );
  });

  testWidgets('a switched-off company is told why on the login screen', (
    tester,
  ) async {
    repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);

    repository.sessionExpired.add(SessionEndReason.companyInactive);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('ບໍລິສັດຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ HR.'),
      findsOneWidget,
    );
  });

  testWidgets('a sign-out the user chose says nothing', (tester) async {
    repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));

    await launch(tester);
    await container.read(authSessionProvider.notifier).logout();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('ເຊສຊັນຂອງທ່ານໝົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.'),
      findsNothing,
    );
  });

  testWidgets('signing out from the change screen returns to login', (
    tester,
  ) async {
    repository.restoreResult = Result.success(
      AuthSession.signedIn(testUser(), mustChangePassword: true),
    );

    await launch(tester);
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    await tester.ensureVisible(find.text('ອອກຈາກລະບົບ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ອອກຈາກລະບົບ'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
