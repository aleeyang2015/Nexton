import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';

import '../support/auth_test_doubles.dart';

void main() {
  final bootstrapping = const AuthSession.bootstrapping();
  final signedOut = const AuthSession.unauthenticated();
  final signedIn = AuthSession.signedIn(testUser());
  final owesPassword = AuthSession.signedIn(
    testUser(),
    mustChangePassword: true,
  );

  String? redirect(AuthSession session, String location) =>
      authRedirect(session: session, location: location);

  group('cold start', () {
    test('holds on the login screen until the session resolves', () {
      expect(redirect(bootstrapping, AppRoutes.login), isNull);
      expect(redirect(bootstrapping, AppRoutes.home), AppRoutes.login);
      expect(
        redirect(bootstrapping, AppRoutes.changePassword),
        AppRoutes.login,
      );
    });
  });

  group('signed out', () {
    test('every route funnels to login', () {
      expect(redirect(signedOut, AppRoutes.home), AppRoutes.login);
      expect(redirect(signedOut, AppRoutes.changePassword), AppRoutes.login);
      expect(redirect(signedOut, '/some/deep/link'), AppRoutes.login);
    });

    test('login itself is left alone', () {
      expect(redirect(signedOut, AppRoutes.login), isNull);
    });
  });

  group('must_change_password', () {
    test('cannot be bypassed by any route', () {
      expect(redirect(owesPassword, AppRoutes.home), AppRoutes.changePassword);
      expect(redirect(owesPassword, AppRoutes.login), AppRoutes.changePassword);
      expect(
        redirect(owesPassword, '/some/deep/link'),
        AppRoutes.changePassword,
      );
      expect(
        redirect(owesPassword, AppRoutes.notFound),
        AppRoutes.changePassword,
      );
    });

    test('the change-password screen itself is reachable', () {
      expect(redirect(owesPassword, AppRoutes.changePassword), isNull);
    });

    test('outranks the signed-in bounce off the auth screens', () {
      // A pending change is checked before "you are in, leave /login".
      expect(
        redirect(owesPassword, AppRoutes.login),
        isNot(equals(AppRoutes.home)),
      );
    });
  });

  group('signed in', () {
    test('is bounced off the login screen', () {
      expect(redirect(signedIn, AppRoutes.login), AppRoutes.home);
    });

    test('may visit the change-password screen voluntarily', () {
      // Changing your password is not something you should have to be forced
      // into to be allowed to do.
      expect(redirect(signedIn, AppRoutes.changePassword), isNull);
    });

    test('is left alone everywhere else', () {
      expect(redirect(signedIn, AppRoutes.home), isNull);
      expect(redirect(signedIn, '/some/deep/link'), isNull);
    });
  });

  group('full flow', () {
    test('login → change password → home', () {
      // Fresh launch.
      expect(redirect(bootstrapping, AppRoutes.home), AppRoutes.login);
      // Logged in, but the backend wants a new password.
      expect(redirect(owesPassword, AppRoutes.login), AppRoutes.changePassword);
      // Tries to escape to home mid-way.
      expect(redirect(owesPassword, AppRoutes.home), AppRoutes.changePassword);
      // Change succeeds — the session is released and the page navigates home.
      expect(redirect(signedIn, AppRoutes.home), isNull);
      // And a later sign-out sends them back.
      expect(redirect(signedOut, AppRoutes.home), AppRoutes.login);
    });
  });
}
