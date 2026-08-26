import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip.dart';
import '../repositories/salary_repository.dart';

/// Loads the salary-history page's list for a given year.
class GetPayslipHistoryUseCase implements BaseUseCase<List<Payslip>, int> {
  final SalaryRepository _repository;

  GetPayslipHistoryUseCase(this._repository);

  @override
  FutureResult<List<Payslip>> call(int year) => _repository.history(year);
}
