import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../features/change_password/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../core/widgets/error_page.dart';
import '../widgets/main_shell_page.dart';

/// Route paths, so the redirect rules and the route table can't disagree.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String notFound = '/404';
}

/// The whole navigation policy for a session, as a pure function so it can be
/// tested without a widget tree.
///
/// Order matters:
/// 1. a cold start that hasn't resolved yet parks on the login screen rather
///    than flashing a shell it may have to take away;
/// 2. no session → login;
/// 3. a pending password change outranks everything else, so no deep link,
///    route restoration or manual navigation can walk around it;
/// 4. a full session is bounced off the login screen — but **not** off the
///    change-password screen, which stays reachable so an employee can change
///    their password whenever they want. The forced flow still leaves it: the
///    session drops `mustChangePassword` on success and the page navigates
///    home itself.
String? authRedirect({required AuthSession session, required String location}) {
  final atLogin = location == AppRoutes.login;
  final atChangePassword = location == AppRoutes.changePassword;

  if (session.status == AuthStatus.bootstrapping || !session.hasSession) {
    return atLogin ? null : AppRoutes.login;
  }

  if (session.mustChangePassword) {
    return atChangePassword ? null : AppRoutes.changePassword;
  }

  return atLogin ? AppRoutes.home : null;
}

/// Go Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridges the session provider into something GoRouter can listen to, so a
  // sign-out — including one forced by the 401 interceptor — re-runs the
  // redirect instead of leaving the user on a screen they have no token for.
  final session = ValueNotifier<AuthSession>(const AuthSession.bootstrapping());
  ref.onDispose(session.dispose);

  ref.listen(
    authSessionProvider,
    (_, next) =>
        session.value = next.valueOrNull ?? const AuthSession.bootstrapping(),
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: session,
    redirect: (context, state) =>
        authRedirect(session: session.value, location: state.matchedLocation),
    routes: [
      // Main routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainShellPage(),
        routes: [
          // Add nested routes here
        ],
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // 404 Route
      GoRoute(
        path: AppRoutes.notFound,
        name: 'notFound',
        builder: (context, state) => const NotFoundPage(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => NotFoundPage(error: state.error),

    // Navigation configuration
    navigatorKey: GlobalKey<NavigatorState>(),
  );
});
