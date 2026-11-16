import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_days_off.dart';
import '../repositories/leave_repository.dart';

/// Loads the company's days off (`GET /core_hr/rest-days`), which the leave
/// form greys out and leaves out of a date range's count.
class GetCompanyDaysOffUseCase implements NoParamsUseCase<CompanyDaysOff> {
  final LeaveRepository _repository;

  GetCompanyDaysOffUseCase(this._repository);

  @override
  FutureResult<CompanyDaysOff> call() => _repository.companyDaysOff();
}
