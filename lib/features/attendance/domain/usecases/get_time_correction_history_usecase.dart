import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_record.dart';
import '../repositories/attendance_repository.dart';

/// Loads the employee's filed time-correction requests for the history page.
class GetTimeCorrectionHistoryUseCase
    implements NoParamsUseCase<List<TimeCorrectionRecord>> {
  final AttendanceRepository _repository;

  GetTimeCorrectionHistoryUseCase(this._repository);

  @override
  FutureResult<List<TimeCorrectionRecord>> call() =>
      _repository.myTimeCorrections();
}
