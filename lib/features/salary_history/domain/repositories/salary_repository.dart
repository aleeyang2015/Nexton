import '../../../../core/utils/result.dart';
import '../entities/payslip_pdf.dart';
import '../entities/payslip_record.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class SalaryRepository {
  /// The rendered PDF for one payslip.
  FutureResult<PayslipPdf> pdf(String id);

  /// The caller's payslips for [year] as the server sends them, in its
  /// order: totals only, no lines. Empty for a login with no employee
  /// record.
  FutureResult<List<PayslipRecord>> myPayslips(int year);

  /// One of the caller's payslips in full, as the server sends it. A
  /// payslip that is not there (or not the caller's, or not yet approved)
  /// fails with status 404.
  FutureResult<PayslipRecord> myPayslip(String id);

  /// The caller's newest payslip by pay month, whatever year, or null when
  /// there is none (or no employee record).
  FutureResult<PayslipLatest?> myLatestPayslip();
}
