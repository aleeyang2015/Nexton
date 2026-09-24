import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_request.dart';
import '../repositories/attendance_repository.dart';

/// Files a time-correction request (`POST /attendance/correction-requests`).
///
/// Re-validates even though the form already did: this is the one gate every
/// request passes through before it reaches the network.
class SubmitTimeCorrectionUseCase
    implements BaseUseCase<Unit, TimeCorrectionRequest> {
  final AttendanceRepository _repository;

  SubmitTimeCorrectionUseCase(this._repository);

  @override
  FutureResult<Unit> call(TimeCorrectionRequest params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.submitTimeCorrection(params);
  }
}
