import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_type.dart';
import '../repositories/leave_repository.dart';

/// Loads the leave-type dropdown (`GET /leave/types`).
class GetLeaveTypesUseCase implements NoParamsUseCase<List<LeaveType>> {
  final LeaveRepository _repository;

  GetLeaveTypesUseCase(this._repository);

  @override
  FutureResult<List<LeaveType>> call() => _repository.leaveTypes();
}
