import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_detail.dart';
import '../repositories/attendance_repository.dart';

/// Loads one time-correction request, by id, for the detail page.
class GetTimeCorrectionDetailUseCase
    implements BaseUseCase<TimeCorrectionDetail, String> {
  final AttendanceRepository _repository;

  GetTimeCorrectionDetailUseCase(this._repository);

  @override
  FutureResult<TimeCorrectionDetail> call(String id) =>
      _repository.timeCorrectionDetail(id);
}
