import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/attendance_repository.dart';

/// Loads one status bucket of the time-correction requests the signed-in
/// approver is involved in, for the "ຄຳຮ້ອງແກ້ໄຂເວລາ" page.
///
/// The status is the endpoint's own filter, not a local one: it is read
/// against the caller's step, so `pending` means "still waiting on you".
class GetTimeCorrectionApprovalsUseCase
    implements BaseUseCase<List<TimeCorrectionDetail>, TimeCorrectionStatus?> {
  final AttendanceRepository _repository;

  GetTimeCorrectionApprovalsUseCase(this._repository);

  @override
  FutureResult<List<TimeCorrectionDetail>> call(TimeCorrectionStatus? status) =>
      _repository.timeCorrectionApprovals(status: status);
}
