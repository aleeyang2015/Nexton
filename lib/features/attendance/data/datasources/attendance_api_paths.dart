/// The attendance routes, relative to the client's `/api/v1` base URL.
///
/// Feature-local on purpose: `core/network/api_paths.dart` is reserved for
/// routes the network layer itself has to know about (refresh, the session
/// probe). Everything else belongs to the feature that calls it.
class AttendancePaths {
  AttendancePaths._();

  static const String _prefix = '/core_hr/attendance';

  static const String clockIn = '$_prefix/clock-in';
  static const String clockOut = '$_prefix/clock-out';
  static const String myRecords = '$_prefix/records/my';
  static const String myCheckins = '$_prefix/checkins/my';
  static const String mySummary = '$_prefix/records/summary/my';
}
