import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/attendance_day.dart';
import '../repositories/attendance_repository.dart';

/// Loads today's record so the card can open in the right state instead of
/// assuming "not checked in" (§6.2).
class GetTodayAttendanceUseCase implements NoParamsUseCase<AttendanceDay> {
  final AttendanceRepository _repository;

  GetTodayAttendanceUseCase(this._repository);

  @override
  FutureResult<AttendanceDay> call() => _repository.todayRecord();
}
