import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_detail.dart';
import '../repositories/attendance_repository.dart';

/// Loads the time-correction requests the signed-in approver decides on, for
/// the "ຄຳຮ້ອງແກ້ໄຂເວລາ" page.
class GetTimeCorrectionApprovalsUseCase
    implements NoParamsUseCase<List<TimeCorrectionDetail>> {
  final AttendanceRepository _repository;

  GetTimeCorrectionApprovalsUseCase(this._repository);

  @override
  FutureResult<List<TimeCorrectionDetail>> call() =>
      _repository.timeCorrectionApprovals();
}
