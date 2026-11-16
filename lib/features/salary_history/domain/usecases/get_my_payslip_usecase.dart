import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip_record.dart';
import '../repositories/salary_repository.dart';

/// Loads one of the caller's payslips in full, with its lines, benefits,
/// deductions and overtime (`GET /payroll/payslips/my/:id`).
class GetMyPayslipUseCase implements BaseUseCase<PayslipRecord, String> {
  final SalaryRepository _repository;

  GetMyPayslipUseCase(this._repository);

  @override
  FutureResult<PayslipRecord> call(String id) => _repository.myPayslip(id);
}
