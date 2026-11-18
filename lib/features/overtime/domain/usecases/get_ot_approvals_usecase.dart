import '../../../../core/utils/result.dart';
import '../entities/ot_page.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// One page of the OT requests at the signed-in head's approval steps
/// (`GET /ot-requests/my-approvals`, #48), by number.
class GetOtApprovalsUseCase {
  final OtRepository _repository;

  GetOtApprovalsUseCase(this._repository);

  FutureResult<OtPage<OtRequest>> call(
    OtApprovalStatus status, {
    int page = 1,
  }) => _repository.myApprovals(status: status, page: page);
}
