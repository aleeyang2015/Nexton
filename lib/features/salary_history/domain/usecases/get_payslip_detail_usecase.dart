import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payslip.dart';
import '../repositories/salary_repository.dart';

/// Loads the payslip-detail page's full breakdown for one payslip id.
class GetPayslipDetailUseCase implements BaseUseCase<Payslip, String> {
  final SalaryRepository _repository;

  GetPayslipDetailUseCase(this._repository);

  @override
  FutureResult<Payslip> call(String id) => _repository.detail(id);
}
