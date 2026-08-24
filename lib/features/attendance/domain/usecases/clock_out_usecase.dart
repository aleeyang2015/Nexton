import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/punch_outcome.dart';
import '../entities/punch_request.dart';
import '../repositories/attendance_repository.dart';

/// Records the end of a session.
///
/// The extra rules clock-out carries (§4) are all enforced server-side and
/// come back as [PunchBlocked]; the only one with a recovery path is
/// [AttendanceRule.earlyCheckoutRequiresReason], which the caller resolves by
/// re-invoking this use case with `notes` set.
class ClockOutUseCase implements BaseUseCase<PunchOutcome, PunchRequest> {
  final AttendanceRepository _repository;

  ClockOutUseCase(this._repository);

  @override
  FutureResult<PunchOutcome> call(PunchRequest params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.clockOut(params);
  }
}
