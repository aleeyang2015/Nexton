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
  static const String correctionRequests = '$_prefix/correction-requests';

  static const String myCorrectionRequests = '$correctionRequests/my';

  /// The requests awaiting (or already given) the caller's decision — the
  /// same `my-approvals` convention as `LeavePaths.myApprovals`.
  static const String myCorrectionApprovals =
      '$correctionRequests/my-approvals';

  static String correctionRequest(String id) => '$correctionRequests/$id';

  static String cancelCorrectionRequest(String id) =>
      '$correctionRequests/$id/cancel';

  static String approveCorrectionRequest(String id) =>
      '$correctionRequests/$id/approve';

  static String rejectCorrectionRequest(String id) =>
      '$correctionRequests/$id/reject';

  /// Off-site scan requests — the "ສະແກນນອກພື້ນທີ່" menu
  /// (attendance-offsite-requests.md §2). The detail route comes with the menu
  /// that calls it.
  static const String offsiteRequests = '$_prefix/offsite-requests';

  /// The caller's own off-site requests, for the history page (§4).
  static const String myOffsiteRequests = '$offsiteRequests/my';

  /// The off-site requests awaiting (or already given) the caller's decision.
  static const String myOffsiteApprovals = '$offsiteRequests/my-approvals';

  static String approveOffsiteRequest(String id) =>
      '$offsiteRequests/$id/approve';

  static String rejectOffsiteRequest(String id) =>
      '$offsiteRequests/$id/reject';

  /// The owner withdrawing their own still-pending request (§9).
  static String cancelOffsiteRequest(String id) =>
      '$offsiteRequests/$id/cancel';
}
