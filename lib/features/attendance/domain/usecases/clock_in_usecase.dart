import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/punch_outcome.dart';
import '../entities/punch_request.dart';
import '../repositories/attendance_repository.dart';

/// Records the start of a session.
///
/// Re-validates the request even though [PreparePunchUseCase] already did:
/// the early-checkout retry path rebuilds a request by hand, and this is the
/// only gate every punch passes through.
class ClockInUseCase implements BaseUseCase<PunchOutcome, PunchRequest> {
  final AttendanceRepository _repository;

  ClockInUseCase(this._repository);

  @override
  FutureResult<PunchOutcome> call(PunchRequest params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.clockIn(params);
  }
}
