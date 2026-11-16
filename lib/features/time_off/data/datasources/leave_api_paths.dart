/// The leave routes, relative to the client's `/api/v1` base URL.
///
/// The guide is the backend's, `Nexton-Backend/docs/integration/
/// leave-request-flutter.md` (§3); the App keeps no copy of it. Every
/// `leave-request-flutter.md §…` in this feature's comments means that file.
/// Where the guide and the Go handler disagree, the handler wins.
///
/// Feature-local on purpose: `core/network/api_paths.dart` is reserved for
/// routes the network layer itself has to know about. Everything else belongs
/// to the feature that calls it — same split as `AttendancePaths`.
class LeavePaths {
  LeavePaths._();

  static const String _prefix = '/core_hr/leave';

  static const String types = '$_prefix/types';
  static const String balancesMy = '$_prefix/balances/my';
  static const String requests = '$_prefix/requests';
  static const String requestsMy = '$_prefix/requests/my';
  static const String myApprovals = '$_prefix/requests/my-approvals';

  /// The company's days off. Not under `/leave`, but only the leave form
  /// reads it.
  static const String restDays = '/core_hr/rest-days';

  static String request(String id) => '$_prefix/requests/$id';
  static String cancel(String id) => '$_prefix/requests/$id/cancel';
  static String approve(String id) => '$_prefix/requests/$id/approve';
  static String reject(String id) => '$_prefix/requests/$id/reject';
}
