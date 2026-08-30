import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Loads one request's full detail (`GET /leave/requests/:id`).
class GetLeaveRequestDetailUseCase
    implements BaseUseCase<LeaveRequest, String> {
  final LeaveRepository _repository;

  GetLeaveRequestDetailUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(String id) => _repository.requestDetail(id);
}
