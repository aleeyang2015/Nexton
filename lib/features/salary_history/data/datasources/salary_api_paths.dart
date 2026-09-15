/// The payroll routes, relative to the client's `/api/v1` base URL.
///
/// Feature-local on purpose — same split as `LeavePaths` / `AttendancePaths`:
/// `core/network/api_paths.dart` only holds routes the network layer itself
/// has to know about.
class SalaryPaths {
  SalaryPaths._();

  static const String payslipsMy = '/payroll/payslips/my';

  static String payslip(String id) => '$payslipsMy/$id';

  /// Lives outside the `/payroll` group on the backend.
  static String payslipPdf(String id) => '/payslips/my/$id/pdf';
}
