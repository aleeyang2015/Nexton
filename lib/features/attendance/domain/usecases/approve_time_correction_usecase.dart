import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/attendance_repository.dart';

/// Approves a pending time-correction request, by id.
class ApproveTimeCorrectionUseCase implements BaseUseCase<Unit, String> {
  final AttendanceRepository _repository;

  ApproveTimeCorrectionUseCase(this._repository);

  @override
  FutureResult<Unit> call(String id) => _repository.approveTimeCorrection(id);
}
