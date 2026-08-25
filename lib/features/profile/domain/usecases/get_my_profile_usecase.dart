import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/employee_profile.dart';
import '../repositories/profile_repository.dart';

/// Loads the signed-in user's employee profile for the home header and the
/// profile page.
class GetMyProfileUseCase implements NoParamsUseCase<EmployeeProfile> {
  final ProfileRepository _repository;

  GetMyProfileUseCase(this._repository);

  @override
  FutureResult<EmployeeProfile> call() => _repository.myProfile();
}
