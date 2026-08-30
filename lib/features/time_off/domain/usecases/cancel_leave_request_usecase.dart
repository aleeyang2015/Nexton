import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Cancels a pending/approved request (`PUT /leave/requests/:id/cancel`).
class CancelLeaveRequestUseCase implements BaseUseCase<LeaveRequest, String> {
  final LeaveRepository _repository;

  CancelLeaveRequestUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(String id) => _repository.cancel(id);
}
