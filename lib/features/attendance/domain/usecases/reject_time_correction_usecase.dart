import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/attendance_repository.dart';

/// Rejects a pending time-correction request. [reason] is required — it is
/// what the employee sees on their request.
class RejectTimeCorrectionUseCase
    implements BaseUseCase<Unit, ({String id, String reason})> {
  final AttendanceRepository _repository;

  RejectTimeCorrectionUseCase(this._repository);

  @override
  FutureResult<Unit> call(({String id, String reason}) p) =>
      _repository.rejectTimeCorrection(p.id, p.reason);
}
