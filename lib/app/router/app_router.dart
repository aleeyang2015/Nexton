import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/approvals/approvals_page.dart';
import '../../features/approvals/presentation/pages/leave_approval_detail_page.dart';
import '../../features/approvals/presentation/providers/approver_access_provider.dart';
import '../../features/attendance/presentation/pages/attendance_history_page.dart';
import '../../features/attendance/presentation/pages/camera_capture_page.dart';
import '../../features/attendance/domain/entities/offsite_method.dart';
import '../../features/attendance/domain/correction_rules.dart';
import '../../features/attendance/domain/entities/offsite_detail.dart';
import '../../features/attendance/presentation/pages/my_requests_page.dart';
import '../../features/attendance/presentation/pages/offsite_request_detail_page.dart';
import '../../features/attendance/presentation/pages/offsite_request_page.dart';
import '../../features/attendance/presentation/pages/time_correction_approvals_page.dart';
import '../../features/profile/domain/entities/shift_detail.dart';
import '../../features/attendance/presentation/pages/time_correction_history_detail_page.dart';
import '../../features/attendance/domain/entities/time_correction_record.dart';
import '../../features/attendance/presentation/pages/time_correction_request_page.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../features/change_password/presentation/pages/change_password_page.dart';
import '../../features/overtime/domain/entities/ot_request.dart';
import '../../features/overtime/presentation/pages/ot_ask_page.dart';
import '../../features/overtime/presentation/pages/ot_edit_page.dart';
import '../../features/overtime/presentation/pages/ot_list_page.dart';
import '../../features/overtime/presentation/pages/ot_posts_page.dart';
import '../../features/overtime/presentation/pages/ot_request_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/salary_history/domain/entities/payslip_record.dart';
import '../../features/salary_history/presentation/pages/payslip_detail_page.dart';
import '../../features/salary_history/presentation/pages/payslip_pdf_page.dart';
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
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String attendanceHistory = '/attendance-history';
  static const String timeCorrectionRequest = '/attendance/time-correction';

  /// The "forgot to scan" form filled for [date] and, when given, the shift
  /// part [partId] (#44): `?date=YYYY-MM-DD&part=<id>`.
  static String timeCorrectionRequestFor(DateTime date, {String? partId}) {
    final d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return Uri(
      path: timeCorrectionRequest,
      queryParameters: {'date': d, 'part': ?partId},
    ).toString();
  }
  /// The old "forgot to scan" history address: it opens "My requests" on
  /// that tab (#45).
  static const String timeCorrectionHistory =
      '/attendance/time-correction/history';

  /// The old detail address, with the id as `extra`; it opens the same page
  /// as [myCorrectionRequestDetail].
  static const String timeCorrectionHistoryDetail =
      '/attendance/time-correction/history/detail';
  static const String timeCorrectionApprovals =
      '/attendance/time-correction/approvals';
  static const String offsiteHistory = '/attendance/offsite/history';

  /// "My requests" (#42): the employee's own requests, one tab per kind.
  static const String myRequests = '/attendance/requests';

  /// One of the employee's off-site requests, by id. A route pattern; build
  /// a location with [myOffsiteRequest].
  static const String myOffsiteRequestDetail =
      '/attendance/requests/offsite/:id';

  /// The location of the employee's off-site request [id].
  static String myOffsiteRequest(String id) =>
      '/attendance/requests/offsite/${Uri.encodeComponent(id)}';

  /// One of the employee's "forgot to scan" requests, by id (#45). A route
  /// pattern; build a location with [myCorrectionRequest].
  static const String myCorrectionRequestDetail =
      '/attendance/requests/correction/:id';

  /// The location of the employee's "forgot to scan" request [id].
  static String myCorrectionRequest(String id) =>
      '/attendance/requests/correction/${Uri.encodeComponent(id)}';
  static const String offsiteRequest = '/attendance/offsite';
  static const String cameraCapture = '/attendance/camera';
  static const String timeOff = '/time-off';
  /// One leave request, by its id. Route patterns; build a location with
  /// [timeOffRequest] and [timeOffRequestEditOf].
  static const String timeOffRequestDetail = '/time-off/request/:id';

  /// Under the id, never `/time-off/request/edit`: `:id` would read "edit"
  /// as a request id.
  static const String timeOffRequestEdit = '/time-off/request/:id/edit';

  /// The location of the leave request [id], for a list row, a banner link
  /// or a push notification.
  static String timeOffRequest(String id) =>
      '/time-off/request/${Uri.encodeComponent(id)}';

  /// The location of the edit page of the leave request [id].
  static String timeOffRequestEditOf(String id) =>
      '${timeOffRequest(id)}/edit';
  static const String timeOffLeaveTypePicker = '/time-off/leave-type';
  static const String salaryHistory = '/salary-history';
  /// One payslip, by its id. A route pattern; build a location with
  /// [payslip].
  static const String payslipDetail = '/salary-history/payslip/:id';

  /// The location of the payslip [id], for a list row, a link or a push.
  static String payslip(String id) =>
      '/salary-history/payslip/${Uri.encodeComponent(id)}';

  /// The PDF of a payslip, opened inside the App. A route pattern; build a
  /// location with [payslipPdf].
  static const String payslipPdfPage = '/salary-history/payslip/:id/pdf';

  /// The location of the PDF of the payslip [id].
  static String payslipPdf(String id) => '${payslip(id)}/pdf';
  static const String approvals = '/approvals';

  /// The approver's page of one leave request, by its id. A route pattern;
  /// build a location with [approvalLeave].
  static const String approvalLeaveDetail = '/approvals/leave/:id';

  /// The location of the approver's page of the leave request [id].
  static String approvalLeave(String id) =>
      '/approvals/leave/${Uri.encodeComponent(id)}';

  /// The approver's page of one off-site scan, by its id (#46). A route
  /// pattern; build a location with [approvalOffsite].
  static const String approvalOffsiteDetail = '/approvals/offsite/:id';

  /// The location of the approver's page of off-site scan [id].
  static String approvalOffsite(String id) =>
      '/approvals/offsite/${Uri.encodeComponent(id)}';

  /// The employee's OT requests.
  static const String overtime = '/overtime';

  /// The Ask OT form.
  static const String otAsk = '/overtime/ask';

  /// HR's open OT posts for the user's department.
  static const String otPosts = '/overtime/posts';

  /// One OT request, by its id. A route pattern; build a location with
  /// [otRequest].
  static const String otRequestDetail = '/overtime/request/:id';

  /// The location of the OT request [id], for a list row, another screen or
  /// a push.
  static String otRequest(String id) =>
      '/overtime/request/${Uri.encodeComponent(id)}';

  /// Changing a waiting OT request. A route pattern; build a location with
  /// [otRequestEditOf].
  static const String otRequestEdit = '/overtime/request/:id/edit';

  /// The location of the edit form of the OT request [id].
  static String otRequestEditOf(String id) => '${otRequest(id)}/edit';
  static const String notFound = '/404';
}

/// `/approvals`, kept apart so a test can mount it on its own. Department
/// heads and HR only: a deep link from anyone else finds nothing here.
final List<GoRoute> approvalsRoutes = [
  GoRoute(
    path: AppRoutes.approvals,
    name: 'approvals',
    builder: (context, state) => const _ApprovalsGate(child: ApprovalsPage()),
  ),
  // One leave request as its approver sees it. `extra` may carry the list
  // row, shown while the page loads its own copy.
  GoRoute(
    path: AppRoutes.approvalLeaveDetail,
    name: 'approvalLeaveDetail',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return _ApprovalsGate(
        child: LeaveApprovalDetailPage(
          requestId: id,
          initial: _leaveRequestExtra(state.extra, id),
        ),
      );
    },
  ),
  // One off-site scan for its approver (#46); `extra` may carry the row.
  GoRoute(
    path: AppRoutes.approvalOffsiteDetail,
    name: 'approvalOffsite',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      final extra = state.extra;
      return _ApprovalsGate(
        attendanceOnly: true,
        child: OffsiteRequestDetailPage(
          requestId: id,
          approver: true,
          initial: extra is OffsiteRequestDetail && extra.id == id
              ? extra
              : null,
        ),
      );
    },
  ),
];

/// The payslip page, opened by the payslip's id, so the salary list, a link
/// and a push notification can all open it.
///
/// `extra` may carry the list's row for that payslip, for a first paint
/// while the page loads the whole payslip; it is only used when it is that
/// payslip. With no `extra` the page loads by id alone.
///
/// A list of its own so the path can be tested without the whole App.
final List<GoRoute> payslipRoutes = [
  GoRoute(
    path: AppRoutes.payslipDetail,
    name: 'payslipDetail',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      final extra = state.extra;
      return PayslipDetailPage(
        payslipId: id,
        listRow: extra is PayslipRecord && extra.id == id ? extra : null,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.payslipPdfPage,
    name: 'payslipPdf',
    builder: (context, state) =>
        PayslipPdfPage(payslipId: state.pathParameters['id'] ?? ''),
  ),
];

/// The OT list and an OT request's page, opened by the request's id, so a
/// list row, another screen and a push can all open it.
///
/// `extra` may carry the list's row for that request, for a first paint
/// while the page loads its own copy; it is only used when it is that
/// request.
///
/// A list of its own so the paths can be tested without the whole App.
final List<GoRoute> overtimeRoutes = [
  GoRoute(
    path: AppRoutes.overtime,
    name: 'overtime',
    builder: (context, state) => const OtListPage(),
  ),
  GoRoute(
    path: AppRoutes.otAsk,
    name: 'otAsk',
    builder: (context, state) => const OtAskPage(),
  ),
  GoRoute(
    path: AppRoutes.otPosts,
    name: 'otPosts',
    builder: (context, state) => const OtPostsPage(),
  ),
  GoRoute(
    path: AppRoutes.otRequestDetail,
    name: 'otRequestDetail',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      final extra = state.extra;
      return OtRequestDetailPage(
        requestId: id,
        initial: extra is OtRequest && extra.id == id ? extra : null,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.otRequestEdit,
    name: 'otRequestEdit',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      final extra = state.extra;
      return OtEditPage(
        requestId: id,
        initial: extra is OtRequest && extra.id == id ? extra : null,
      );
    },
  ),
];

/// The leave request page and its edit page, each opened by the request's
/// id, so a history row, the "waiting" banner and a push notification can
/// all open them.
///
/// `extra` may carry the request the caller already has, for a first paint
/// while the page loads its own copy; it is only used when it is that
/// request. With no `extra` the page loads by id.
///
/// A list of its own so the paths can be tested without the whole App.
final List<GoRoute> leaveRequestRoutes = [
  GoRoute(
    path: AppRoutes.timeOffRequestDetail,
    name: 'timeOffRequestDetail',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return LeaveRequestDetailPage(
        requestId: id,
        initial: _leaveRequestExtra(state.extra, id),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.timeOffRequestEdit,
    name: 'timeOffRequestEdit',
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return LeaveRequestEditPage(
        requestId: id,
        initial: _leaveRequestExtra(state.extra, id),
      );
    },
  ),
];

LeaveRequest? _leaveRequestExtra(Object? extra, String id) =>
    extra is LeaveRequest && extra.id == id ? extra : null;

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

      // Profile — pushed from the home header's avatar or name
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
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
      // Time-correction request — the "ລືມລົງເວລາ" menu tile
      GoRoute(
        path: AppRoutes.timeCorrectionRequest,
        name: 'timeCorrectionRequest',
        // `?date=YYYY-MM-DD&part=<id>` fill it in (a history row, #53's
        // push); a history row also passes its session's part as `extra`.
        builder: (context, state) =>
            timeCorrectionRequestPageFor(state.uri.queryParameters, state.extra),
      ),
      // The requests filed from it: the old address opens "My requests" on
      // the "forgot to scan" tab (#45), so a link to it still lands.
      GoRoute(
        path: AppRoutes.timeCorrectionHistory,
        name: 'timeCorrectionHistory',
        builder: (context, state) =>
            const MyRequestsPage(initialTab: MyRequestsTab.correction),
      ),
      // One of those requests by the old address — its id rides along as
      // `extra`, so a direct hit without one falls through to the 404 page.
      GoRoute(
        path: AppRoutes.timeCorrectionHistoryDetail,
        name: 'timeCorrectionHistoryDetail',
        builder: (context, state) {
          final id = state.extra;
          if (id is! String) return const NotFoundPage();
          return TimeCorrectionHistoryDetailPage(id: id);
        },
      ),
      // One "forgot to scan" request, by id (#45); `extra` may carry the
      // list row, shown while the request loads.
      GoRoute(
        path: AppRoutes.myCorrectionRequestDetail,
        name: 'myCorrectionRequest',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          return TimeCorrectionHistoryDetailPage(
            id: id,
            initial: extra is TimeCorrectionRecord && extra.id == id
                ? extra
                : null,
          );
        },
      ),
      // The requests an approver decides on — the "ອະນຸມັດແກ້ໄຂເວລາ" menu tile
      GoRoute(
        path: AppRoutes.timeCorrectionApprovals,
        name: 'timeCorrectionApprovals',
        builder: (context, state) => const TimeCorrectionApprovalsPage(),
      ),
      // The old off-site history address opens "My requests" (#42), so a
      // link to it still lands. The form is not behind it: only a refused
      // punch opens the form.
      GoRoute(
        path: AppRoutes.offsiteHistory,
        name: 'offsiteHistory',
        builder: (context, state) => const MyRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.myRequests,
        name: 'myRequests',
        builder: (context, state) => const MyRequestsPage(),
      ),
      // One off-site request, by id; `extra` may carry the list row.
      GoRoute(
        path: AppRoutes.myOffsiteRequestDetail,
        name: 'myOffsiteRequest',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          return OffsiteRequestDetailPage(
            requestId: id,
            initial: extra is OffsiteRequestDetail && extra.id == id
                ? extra
                : null,
          );
        },
      ),
      // The off-site scan request form. Opened only from a refused clock-in
      // or clock-out, whose direction comes as `extra`; without one (a link,
      // a restored route) there is nothing to file: not found.
      GoRoute(
        path: AppRoutes.offsiteRequest,
        name: 'offsiteRequest',
        builder: (context, state) => offsiteRequestPageFor(state.extra),
      ),
      // Its "ຖ່າຍຮູບ" button — pops with the photo as a `LocalFile`.
      GoRoute(
        path: AppRoutes.cameraCapture,
        name: 'cameraCapture',
        builder: (context, state) => const CameraCapturePage(),
      ),

      // Approvals — the "ອະນຸມັດ" menu tile
      ...approvalsRoutes,

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

      ...leaveRequestRoutes,

      // Leave-type chooser — pushed from the request form's "Leave type" card
      // and the history tab's filter, popped with the selected `leave_type_id`
      // (or `''` from the filter's "All" row). `extra` is a
      // [LeaveTypePickerArgs] record; a bare String or nothing is still
      // accepted and just ticks that id with no "All" row.
      GoRoute(
        path: AppRoutes.timeOffLeaveTypePicker,
        name: 'timeOffLeaveTypePicker',
        builder: (context, state) {
          final extra = state.extra;
          return LeaveTypePickerPage(
            selectedTypeId: switch (extra) {
              LeaveTypePickerArgs(:final selectedTypeId) => selectedTypeId,
              final String id => id,
              _ => null,
            },
            allowClear: extra is LeaveTypePickerArgs && extra.allowClear,
            keepTypeId: extra is LeaveTypePickerArgs ? extra.keepTypeId : null,
          );
        },
      ),

      // Salary history
      GoRoute(
        path: AppRoutes.salaryHistory,
        name: 'salaryHistory',
        builder: (context, state) => const SalaryHistoryPage(),
      ),

      ...payslipRoutes,

      ...overtimeRoutes,

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

/// A page of the Approvals place for those who may see it, the not-found
/// page for anyone else.
class _ApprovalsGate extends ConsumerWidget {
  const _ApprovalsGate({required this.child, this.attendanceOnly = false});

  final Widget child;

  /// Only for attendance approvers too (an off-site scan, #46).
  final bool attendanceOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(
        approverAccessProvider.select(
          (a) =>
              a.canSeeApprovals &&
              (!attendanceOnly || a.canApproveAttendance),
        ),
      )
      ? child
      : const NotFoundPage();
}

/// The off-site form for the refused punch's direction in [extra], or the
/// not-found page when there is none: only a refused clock-in or clock-out
/// opens the form (#40).
Widget offsiteRequestPageFor(Object? extra) => extra is OffsiteMethod
    ? OffsiteRequestPage(method: extra)
    : const NotFoundPage();

/// The "forgot to scan" form for `?date=YYYY-MM-DD&part=<id>` and, from a
/// history row, its session's part as [extra] (#44).
Widget timeCorrectionRequestPageFor(Map<String, String> query, Object? extra) =>
    TimeCorrectionRequestPage(
      date: CorrectionRules.parseDate(query['date']),
      partId: query['part'],
      sessionPart: extra is ShiftDetail ? extra : null,
    );
