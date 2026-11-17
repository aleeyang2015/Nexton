import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip_record.dart';
import '../repositories/salary_repository.dart';

/// Loads the caller's newest payslip, for the salary page's top card
/// (`GET /payroll/payslips/my/latest`). Null when there is none.
class GetMyLatestPayslipUseCase implements NoParamsUseCase<PayslipLatest?> {
  final SalaryRepository _repository;

  GetMyLatestPayslipUseCase(this._repository);

  @override
  FutureResult<PayslipLatest?> call() => _repository.myLatestPayslip();
}
