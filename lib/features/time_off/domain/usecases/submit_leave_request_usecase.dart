import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request_draft.dart';
import '../repositories/leave_repository.dart';

/// Submits the request-leave form.
class SubmitLeaveRequestUseCase
    implements BaseUseCase<Unit, LeaveRequestDraft> {
  final LeaveRepository _repository;

  SubmitLeaveRequestUseCase(this._repository);

  @override
  FutureResult<Unit> call(LeaveRequestDraft draft) =>
      _repository.submit(draft);
}
