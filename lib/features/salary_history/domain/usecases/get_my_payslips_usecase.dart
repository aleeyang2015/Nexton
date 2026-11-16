import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip_record.dart';
import '../repositories/salary_repository.dart';

/// Loads the caller's payslips for one year, as the server sends them
/// (`GET /payroll/payslips/my?year=`). List rows carry the totals only, no
/// lines.
class GetMyPayslipsUseCase implements BaseUseCase<List<PayslipRecord>, int> {
  final SalaryRepository _repository;

  GetMyPayslipsUseCase(this._repository);

  @override
  FutureResult<List<PayslipRecord>> call(int year) =>
      _repository.myPayslips(year);
}
