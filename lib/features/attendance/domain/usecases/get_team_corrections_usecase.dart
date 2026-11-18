import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/time_correction_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/attendance_repository.dart';

/// One page of the head's team's "forgot to scan" requests, read-only
/// (#50), by number.
class GetTeamCorrectionsUseCase {
  final AttendanceRepository _repository;

  GetTeamCorrectionsUseCase(this._repository);

  FutureResult<NumberedPage<TimeCorrectionDetail>> call({
    TimeCorrectionStatus? status,
    int page = 1,
  }) => _repository.teamTimeCorrections(status: status, page: page);
}
