import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/attendance_repository.dart';

/// Withdraws a pending time-correction request, by id.
class CancelTimeCorrectionUseCase implements BaseUseCase<Unit, String> {
  final AttendanceRepository _repository;

  CancelTimeCorrectionUseCase(this._repository);

  @override
  FutureResult<Unit> call(String id) => _repository.cancelTimeCorrection(id);
}
