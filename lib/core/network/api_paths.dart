/// Route paths that are session infrastructure rather than feature detail:
/// the network layer itself has to know how to refresh a token and which call
/// is the canonical "is my session still valid" probe. The auth feature reuses
/// these constants so there is exactly one spelling of each route.
class ApiPaths {
  ApiPaths._();

  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
}
