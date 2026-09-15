import '../../../../core/utils/result.dart';
import '../entities/payslip.dart';
import '../entities/payslip_pdf.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class SalaryRepository {
  /// Every payslip for [year], newest month first. Aggregates only — no
  /// line items.
  FutureResult<List<Payslip>> history(int year);

  /// One payslip in full, line items included.
  FutureResult<Payslip> detail(String id);

  /// The rendered PDF for one payslip.
  FutureResult<PayslipPdf> pdf(String id);
}
