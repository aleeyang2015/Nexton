/// The leave routes, relative to the client's `/api/v1` base URL
/// (leave-request-flutter.md §3).
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

  static String request(String id) => '$_prefix/requests/$id';
  static String cancel(String id) => '$_prefix/requests/$id/cancel';
  static String approve(String id) => '$_prefix/requests/$id/approve';
  static String reject(String id) => '$_prefix/requests/$id/reject';
}
