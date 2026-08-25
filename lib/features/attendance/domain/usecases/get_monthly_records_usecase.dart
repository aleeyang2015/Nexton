import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/attendance_day.dart';
import '../entities/date_range.dart';
import '../repositories/attendance_repository.dart';

/// Loads the history page's daily list for a date range.
class GetMonthlyRecordsUseCase implements BaseUseCase<List<AttendanceDay>, DateRange> {
  final AttendanceRepository _repository;

  GetMonthlyRecordsUseCase(this._repository);

  @override
  FutureResult<List<AttendanceDay>> call(DateRange range) =>
      _repository.records(range);
}
