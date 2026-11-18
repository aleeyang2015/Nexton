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
  static const String requestsTeam = '$_prefix/requests/team';

  /// The company's days off. Not under `/leave`, but only the leave form
  /// reads it.
  static const String restDays = '/core_hr/rest-days';

  // The id is one path segment, whatever it holds: an id that came in from
  // a link is not trusted to be a UUID, and `../my` must not become another
  // endpoint.
  static String request(String id) => '$_prefix/requests/${_segment(id)}';
  static String cancel(String id) => '${request(id)}/cancel';
  static String approve(String id) => '${request(id)}/approve';
  static String reject(String id) => '${request(id)}/reject';

  static String _segment(String id) => Uri.encodeComponent(id);
}
