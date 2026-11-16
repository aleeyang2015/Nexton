/// The payroll routes, relative to the client's `/api/v1` base URL.
///
/// Feature-local on purpose — same split as `LeavePaths` / `AttendancePaths`:
/// `core/network/api_paths.dart` only holds routes the network layer itself
/// has to know about.
class SalaryPaths {
  SalaryPaths._();

  static const String payslipsMy = '/payroll/payslips/my';

  /// The id is one path segment, whatever it holds: `../my` must not become
  /// another endpoint. A UUID goes through as it is.
  static String payslip(String id) =>
      '$payslipsMy/${Uri.encodeComponent(id)}';

  static String payslipPdf(String id) => '${payslip(id)}/pdf';
}
