import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_approval.dart';
import '../repositories/leave_repository.dart';

/// Loads the approvals tab's "needs your decision" list.
class GetPendingApprovalsUseCase implements NoParamsUseCase<List<LeaveApproval>> {
  final LeaveRepository _repository;

  GetPendingApprovalsUseCase(this._repository);

  @override
  FutureResult<List<LeaveApproval>> call() => _repository.pendingApprovals();
}
