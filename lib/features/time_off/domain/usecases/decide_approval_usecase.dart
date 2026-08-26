import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/leave_repository.dart';

/// Approves or rejects one subordinate's request.
class DecideApprovalUseCase
    implements BaseUseCase<Unit, ({String requestId, bool approve})> {
  final LeaveRepository _repository;

  DecideApprovalUseCase(this._repository);

  @override
  FutureResult<Unit> call(({String requestId, bool approve}) params) =>
      _repository.decideApproval(
        requestId: params.requestId,
        approve: params.approve,
      );
}
