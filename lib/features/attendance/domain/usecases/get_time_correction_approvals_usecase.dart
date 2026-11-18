import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/attendance_repository.dart';

/// The approver's list asked for and where to go on from.
typedef TimeCorrectionApprovalsPageParams = ({
  TimeCorrectionStatus status,
  String? cursor,
});

/// One page of the "forgot to scan" requests the signed-in approver is
/// involved in, for the approvals page's tab (#47).
///
/// The status is the endpoint's own filter, not a local one: it is read
/// against the caller's step, so `pending` means "still waiting on you" and
/// `approved` / `rejected` "a step you decided".
class GetTimeCorrectionApprovalsUseCase {
  final AttendanceRepository _repository;

  GetTimeCorrectionApprovalsUseCase(this._repository);

  FutureResult<CursorPage<TimeCorrectionDetail>> call(
    TimeCorrectionApprovalsPageParams params,
  ) => _repository.timeCorrectionApprovals(
    status: params.status,
    cursor: params.cursor,
  );
}
