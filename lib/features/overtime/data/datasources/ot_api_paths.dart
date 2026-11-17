/// The overtime routes, relative to the client's `/api/v1` base URL
/// (`corehr/attendance/routes.go`).
///
/// Feature-local on purpose, as `LeavePaths`: `core/network/api_paths.dart`
/// is reserved for routes the network layer itself has to know about.
class OtPaths {
  OtPaths._();

  static const String _prefix = '/core_hr/attendance';

  static const String requests = '$_prefix/ot-requests';
  static const String requestsMy = '$_prefix/ot-requests/my';
  static const String openPosts = '$_prefix/ot-announcements/open';

  // The id is one path segment, whatever it holds: an id that came in from
  // a link is not trusted to be a UUID, and `../my` must not become another
  // endpoint.
  static String request(String id) => '$requests/${_segment(id)}';
  static String cancel(String id) => '${request(id)}/cancel';
  static String join(String postId) =>
      '$_prefix/ot-announcements/${_segment(postId)}/join';

  static String _segment(String id) => Uri.encodeComponent(id);
}
