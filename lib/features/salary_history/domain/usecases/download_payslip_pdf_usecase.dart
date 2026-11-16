import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip_pdf.dart';
import '../repositories/salary_repository.dart';

/// Fetches the rendered PDF for one payslip id — what the "Download Payslip
/// (PDF)" button and the detail page's save icon run.
class DownloadPayslipPdfUseCase implements BaseUseCase<PayslipPdf, String> {
  final SalaryRepository _repository;

  DownloadPayslipPdfUseCase(this._repository);

  @override
  FutureResult<PayslipPdf> call(String id) => _repository.pdf(id);
}
