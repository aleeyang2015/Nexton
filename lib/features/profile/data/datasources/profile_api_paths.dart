/// The profile routes, relative to the client's `/api/v1` base URL.
///
/// Feature-local on purpose, same convention as `AttendancePaths`:
/// `core/network/api_paths.dart` is reserved for routes the network layer
/// itself has to know about.
class ProfilePaths {
  ProfilePaths._();

  static const String me = '/core_hr/employees/me';
}
