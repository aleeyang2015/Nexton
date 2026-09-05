import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:next_on/features/change_password/presentation/pages/change_password_page.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/auth_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

const _submitLabel = 'ບັນທຶກລະຫັດຜ່ານ';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository()
      ..restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );
  });

  tearDown(() => repository.sessionExpired.close());

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/change-password',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/change-password',
          builder: (_, __) => const ChangePasswordPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp.router(
            // AppToast resolves its messenger through this key.
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            routerConfig: router,
            // Lao is the app default (see core/l10n/locale_provider.dart) —
            // matched here so the literal Lao strings below still find text.
            locale: const Locale('lo'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldAt(int index) => find.descendant(
    of: find.byType(AuthPasswordField).at(index),
    matching: find.byType(TextField),
  );

  Future<void> fillForm(
    WidgetTester tester, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    await tester.enterText(fieldAt(0), current);
    await tester.enterText(fieldAt(1), next);
    await tester.enterText(fieldAt(2), confirm);
    await tester.pump();
  }

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(ElevatedButton, _submitLabel));

  testWidgets('renders the three password fields and the forced notice', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(AuthPasswordField), findsNWidgets(3));
    expect(find.text('ລະຫັດຜ່ານປັດຈຸບັນ'), findsOneWidget);
    expect(find.text('ລະຫັດຜ່ານໃໝ່'), findsOneWidget);
    expect(find.text('ຢືນຢັນລະຫັດຜ່ານໃໝ່'), findsOneWidget);
    expect(
      find.text('ກະລຸນາຕັ້ງລະຫັດຜ່ານໃໝ່ກ່ອນເຂົ້ານຳໃຊ້ລະບົບ'),
      findsOneWidget,
    );
    expect(find.text('ອອກຈາກລະບົບ'), findsOneWidget);
  });

  testWidgets('the submit button is disabled until all three are filled', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(submitButton(tester).onPressed, isNull);

    await tester.enterText(fieldAt(0), 'current-pass');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull);

    await tester.enterText(fieldAt(1), 'new-password');
    await tester.enterText(fieldAt(2), 'new-password');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('the visibility toggle unmasks a field', (tester) async {
    await pumpPage(tester);
    expect(tester.widget<TextField>(fieldAt(0)).obscureText, isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(AuthPasswordField).first,
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();

    expect(tester.widget<TextField>(fieldAt(0)).obscureText, isFalse);
  });

  testWidgets('a short new password is rejected before the API is called', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillForm(tester, current: 'current-pass', next: 'sh', confirm: 'sh');

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(find.text('ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ຕົວອັກສອນ'), findsOneWidget);
    expect(repository.changePasswordCalls, 0);
  });

  testWidgets('a mismatched confirmation is reported on its own field', (
    tester,
  ) async {
    await pumpPage(tester);
    await fillForm(
      tester,
      current: 'current-pass',
      next: 'new-password',
      confirm: 'new-passwrd',
    );

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(find.text('ລະຫັດຜ່ານຢືນຢັນບໍ່ຕົງກັນ'), findsOneWidget);
    expect(repository.changePasswordCalls, 0);
  });

  testWidgets('a reused password is rejected', (tester) async {
    await pumpPage(tester);
    await fillForm(
      tester,
      current: 'same-password',
      next: 'same-password',
      confirm: 'same-password',
    );

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(
      find.text('ລະຫັດຜ່ານໃໝ່ຕ້ອງບໍ່ຊ້ຳກັບລະຫັດຜ່ານເກົ່າ'),
      findsOneWidget,
    );
    expect(repository.changePasswordCalls, 0);
  });

  testWidgets('a wrong current password shows the server message and clears '
      'the field', (tester) async {
    repository.changePasswordResult = const Result.failure(
      Failure.auth(message: 'Current password is incorrect'),
    );
    await pumpPage(tester);
    await fillForm(
      tester,
      current: 'wrong-pass',
      next: 'new-password',
      confirm: 'new-password',
    );

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(tester.widget<TextField>(fieldAt(0)).controller!.text, isEmpty);
    // Still stuck on the screen.
    expect(find.byType(ChangePasswordPage), findsOneWidget);
  });

  testWidgets('a transport failure surfaces as a toast', (tester) async {
    repository.changePasswordResult = const Result.failure(
      Failure.network(message: 'No internet connection'),
    );
    await pumpPage(tester);
    await fillForm(
      tester,
      current: 'current-pass',
      next: 'new-password',
      confirm: 'new-password',
    );

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SnackBar, 'No internet connection'),
      findsOneWidget,
    );
    expect(find.byType(ChangePasswordPage), findsOneWidget);
  });

  testWidgets('a successful change sends the user to the app', (tester) async {
    await pumpPage(tester);
    await fillForm(
      tester,
      current: 'current-pass',
      next: 'new-password',
      confirm: 'new-password',
    );

    await tester.tap(find.text(_submitLabel));
    await tester.pumpAndSettle();

    expect(repository.changePasswordCalls, 1);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsNothing);
  });

  testWidgets('signing out is available as the way off the screen', (
    tester,
  ) async {
    await pumpPage(tester);

    // Below the fold on a small viewport.
    await tester.ensureVisible(find.text('ອອກຈາກລະບົບ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ອອກຈາກລະບົບ'));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
  });
}
