import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/offsite_repository.dart';

/// The approver's list asked for and where to go on from.
typedef OffsiteApprovalsPageParams = ({
  TimeCorrectionStatus status,
  String? cursor,
});

/// One page of the off-site scan requests the signed-in approver is involved
/// in, for the approvals page's off-site tab (#46).
///
/// The status is the endpoint's own filter, not a local one: it is read against
/// the caller's step, so `pending` means "still waiting on you" and
/// `approved` / `rejected` "a step you decided".
class GetOffsiteApprovalsUseCase {
  final OffsiteRepository _repository;

  GetOffsiteApprovalsUseCase(this._repository);

  FutureResult<CursorPage<OffsiteRequestDetail>> call(
    OffsiteApprovalsPageParams params,
  ) => _repository.approvals(status: params.status, cursor: params.cursor);
}
