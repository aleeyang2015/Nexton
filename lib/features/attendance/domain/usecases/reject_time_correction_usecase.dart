import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/attendance_repository.dart';

/// Rejects a pending time-correction request. [note] is required — it is
/// what the employee sees on their request. [stepId] guards against the
/// step having moved on, as on [ApproveTimeCorrectionUseCase].
class RejectTimeCorrectionUseCase
    implements BaseUseCase<Unit, ({String id, String note, String? stepId})> {
  final AttendanceRepository _repository;

  RejectTimeCorrectionUseCase(this._repository);

  @override
  FutureResult<Unit> call(({String id, String note, String? stepId}) p) =>
      _repository.rejectTimeCorrection(p.id, note: p.note, stepId: p.stepId);
}
