import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/features/app_gate/domain/app_gate_status.dart';
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
    test('holds on home until the session resolves', () {
      expect(redirect(bootstrapping, AppRoutes.home), isNull);
      expect(redirect(bootstrapping, AppRoutes.login), AppRoutes.home);
      expect(
        redirect(bootstrapping, AppRoutes.changePassword),
        AppRoutes.home,
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
      expect(redirect(bootstrapping, AppRoutes.home), isNull);
      // The session resolves signed out.
      expect(redirect(signedOut, AppRoutes.home), AppRoutes.login);
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

  group('the version gate (#57) comes first', () {
    const update = AppGateUpdateRequired();
    const down = AppGateMaintenance('Back at 10:00');

    String? gated(AuthSession session, String location, AppGateStatus gate) =>
        authRedirect(session: session, location: location, gate: gate);

    test('too old: every location, before the session rules', () {
      for (final session in [
        bootstrapping,
        signedOut,
        signedIn,
        owesPassword,
      ]) {
        for (final location in [
          AppRoutes.home,
          AppRoutes.login,
          AppRoutes.changePassword,
          '/some/deep/link',
        ]) {
          expect(
            gated(session, location, update),
            AppRoutes.updateRequired,
            reason: '$session at $location',
          );
        }
        expect(gated(session, AppRoutes.updateRequired, update), isNull);
      }
    });

    test('maintenance: every location, its own screen', () {
      expect(gated(signedOut, AppRoutes.login, down), AppRoutes.maintenance);
      expect(
        gated(owesPassword, AppRoutes.changePassword, down),
        AppRoutes.maintenance,
      );
      expect(gated(signedIn, AppRoutes.maintenance, down), isNull);
      // From the update screen, when the server goes down meanwhile.
      expect(
        gated(signedIn, AppRoutes.updateRequired, down),
        AppRoutes.maintenance,
      );
    });

    test('back to ok: the gate screen goes home, then the session rules', () {
      const ok = AppGateOk();
      expect(gated(signedIn, AppRoutes.maintenance, ok), AppRoutes.home);
      expect(gated(signedIn, AppRoutes.updateRequired, ok), AppRoutes.home);
      // Home then sends the signed-out to login, as before.
      expect(gated(signedOut, AppRoutes.home, ok), AppRoutes.login);
    });

    test('ok changes nothing elsewhere', () {
      const ok = AppGateOk();
      expect(gated(signedIn, '/time-off', ok), isNull);
      expect(gated(signedOut, AppRoutes.login, ok), isNull);
    });
  });
}
