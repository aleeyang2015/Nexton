import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/attendance_summary.dart';
import '../entities/date_range.dart';
import '../repositories/attendance_repository.dart';

/// Loads the history page's stat cards for a date range.
class GetMonthlySummaryUseCase implements BaseUseCase<AttendanceSummary, DateRange> {
  final AttendanceRepository _repository;

  GetMonthlySummaryUseCase(this._repository);

  @override
  FutureResult<AttendanceSummary> call(DateRange range) =>
      _repository.summary(range);
}
