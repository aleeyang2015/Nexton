import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_record.dart';
import '../entities/time_correction_status.dart';
import '../repositories/attendance_repository.dart';

/// The status picked and where to go on from: one page of "My requests"'
/// "forgot to scan" tab.
typedef TimeCorrectionHistoryPageParams = ({
  TimeCorrectionStatus? status,
  String? cursor,
});

/// One page of the time-correction requests the employee has filed, for
/// "My requests" (#45). The status is a server filter, so each picked status
/// pages through its own list.
class GetTimeCorrectionHistoryUseCase {
  final AttendanceRepository _repository;

  GetTimeCorrectionHistoryUseCase(this._repository);

  FutureResult<CursorPage<TimeCorrectionRecord>> call(
    TimeCorrectionHistoryPageParams params,
  ) => _repository.myTimeCorrections(
    status: params.status,
    cursor: params.cursor,
  );
}
