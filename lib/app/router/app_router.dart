import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/presentation/pages/attendance_history_page.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../features/change_password/presentation/pages/change_password_page.dart';
import '../../features/salary_history/domain/entities/payslip.dart';
import '../../features/salary_history/presentation/pages/payslip_detail_page.dart';
import '../../features/salary_history/presentation/pages/salary_history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/time_off/domain/entities/leave_request.dart';
import '../../features/time_off/presentation/pages/leave_request_detail_page.dart';
import '../../features/time_off/presentation/pages/leave_request_edit_page.dart';
import '../../features/time_off/presentation/pages/leave_type_picker_page.dart';
import '../../features/time_off/presentation/pages/time_off_page.dart';
import '../../core/widgets/error_page.dart';
import '../widgets/main_shell_page.dart';

/// Route paths, so the redirect rules and the route table can't disagree.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String attendanceHistory = '/attendance-history';
  static const String timeOff = '/time-off';
  static const String timeOffRequestDetail = '/time-off/request';
  static const String timeOffRequestEdit = '/time-off/request/edit';
  static const String timeOffLeaveTypePicker = '/time-off/leave-type';
  static const String salaryHistory = '/salary-history';
  static const String payslipDetail = '/salary-history/payslip';
  static const String notFound = '/404';
}

/// The whole navigation policy for a session, as a pure function so it can be
/// tested without a widget tree.
///
/// Order matters:
/// 1. a cold start that hasn't resolved yet parks on home rather than the
///    login screen — [MainShellPage] paints its own shimmer for this status,
///    so an already-signed-in user never sees the login form flash by;
/// 2. no session → login;
/// 3. a pending password change outranks everything else, so no deep link,
///    route restoration or manual navigation can walk around it;
/// 4. a full session is bounced off the login screen — but **not** off the
///    change-password screen, which stays reachable so an employee can change
///    their password whenever they want. The forced flow still leaves it: the
///    session drops `mustChangePassword` on success and the page navigates
///    home itself.
String? authRedirect({required AuthSession session, required String location}) {
  final atHome = location == AppRoutes.home;
  final atLogin = location == AppRoutes.login;
  final atChangePassword = location == AppRoutes.changePassword;

  if (session.status == AuthStatus.bootstrapping) {
    return atHome ? null : AppRoutes.home;
  }

  if (!session.hasSession) {
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
    initialLocation: AppRoutes.home,
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

      // Attendance
      GoRoute(
        path: AppRoutes.attendanceHistory,
        name: 'attendanceHistory',
        builder: (context, state) => const AttendanceHistoryPage(),
      ),

      // Time off
      GoRoute(
        path: AppRoutes.timeOff,
        name: 'timeOff',
        builder: (context, state) => TimeOffPage(
          initialTab: state.extra is TimeOffTab
              ? state.extra as TimeOffTab
              : TimeOffTab.history,
        ),
      ),

      // Leave request detail / edit — reached by tapping a history card; the
      // request rides along as `extra`, so a direct hit with nothing to show
      // falls through to the 404 page (same pattern as payslipDetail).
      GoRoute(
        path: AppRoutes.timeOffRequestDetail,
        name: 'timeOffRequestDetail',
        builder: (context, state) {
          final request = state.extra;
          if (request is! LeaveRequest) return const NotFoundPage();
          return LeaveRequestDetailPage(request: request);
        },
      ),
      GoRoute(
        path: AppRoutes.timeOffRequestEdit,
        name: 'timeOffRequestEdit',
        builder: (context, state) {
          final request = state.extra;
          if (request is! LeaveRequest) return const NotFoundPage();
          return LeaveRequestEditPage(request: request);
        },
      ),

      // Leave-type chooser — pushed from the request form's "Leave type" card
      // and popped with the selected `leave_type_id`. The currently-selected id
      // rides along as `extra` so the list can tick it; a direct hit with
      // nothing selected is fine and just shows the list untouched.
      GoRoute(
        path: AppRoutes.timeOffLeaveTypePicker,
        name: 'timeOffLeaveTypePicker',
        builder: (context, state) => LeaveTypePickerPage(
          selectedTypeId: state.extra is String ? state.extra as String : null,
        ),
      ),

      // Salary history
      GoRoute(
        path: AppRoutes.salaryHistory,
        name: 'salaryHistory',
        builder: (context, state) => const SalaryHistoryPage(),
      ),

      // Payslip detail — reached by tapping a month's card; the payslip
      // rides along as `extra`, so a direct hit with nothing to show falls
      // through to the 404 page.
      GoRoute(
        path: AppRoutes.payslipDetail,
        name: 'payslipDetail',
        builder: (context, state) {
          final payslip = state.extra;
          if (payslip is! Payslip) return const NotFoundPage();
          return PayslipDetailPage(payslip: payslip);
        },
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
