import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_request.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
///
/// There is intentionally no caching here. A punch is the one thing in the
/// app that must never be replayed from memory or retried silently — §7 rule
/// 8 asks the client to *suppress* duplicates, not to add a layer that could
/// manufacture them — so every call goes to the network and the backend's
/// session guard stays the single source of truth.
class AttendanceRepositoryImpl extends BaseRepository
    implements AttendanceRepository {
  final AttendanceRemoteDataSource _remote;

  AttendanceRepositoryImpl({required AttendanceRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<PunchOutcome> clockIn(PunchRequest request) =>
      guard(() => _remote.clockIn(request));

  @override
  FutureResult<PunchOutcome> clockOut(PunchRequest request) =>
      guard(() => _remote.clockOut(request));

  @override
  FutureResult<AttendanceDay> todayRecord() =>
      guard(() => _remote.todayRecord());

  @override
  FutureResult<List<AttendanceDay>> records(DateRange range) =>
      guard(() => _remote.records(range));

  @override
  FutureResult<AttendanceSummary> summary(DateRange range) =>
      guard(() => _remote.summary(range));
}
