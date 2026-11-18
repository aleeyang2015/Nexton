import 'dart:typed_data';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/open_ot_session.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_request.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_request.dart';
import '../../domain/entities/time_correction_status.dart';
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
  FutureResult<OpenOtSession?> openOtSession() =>
      guard(() => _remote.openOtSession());

  @override
  FutureResult<List<AttendanceDay>> records(DateRange range) =>
      guard(() => _remote.records(range));

  @override
  FutureResult<AttendanceSummary> summary(DateRange range) =>
      guard(() => _remote.summary(range));

  @override
  FutureResult<String?> submitTimeCorrection(TimeCorrectionRequest request) =>
      guard(() => _remote.submitTimeCorrection(request));

  @override
  FutureResult<CursorPage<TimeCorrectionRecord>> myTimeCorrections({
    TimeCorrectionStatus? status,
    String? cursor,
  }) => guard(
    () => _remote.myTimeCorrections(status: status, cursor: cursor),
  );

  @override
  FutureResult<TimeCorrectionDetail> timeCorrectionDetail(String id) =>
      guard(() => _remote.timeCorrectionDetail(id));

  @override
  FutureResult<Unit> cancelTimeCorrection(String id) => guard(() async {
    await _remote.cancelTimeCorrection(id);
    return Unit.instance;
  });

  @override
  FutureResult<List<TimeCorrectionDetail>> timeCorrectionApprovals({
    TimeCorrectionStatus? status,
  }) => guard(() => _remote.timeCorrectionApprovals(status: status));

  @override
  FutureResult<Unit> approveTimeCorrection(String id, {String? stepId}) =>
      guard(() async {
        await _remote.approveTimeCorrection(id, stepId: stepId);
        return Unit.instance;
      });

  @override
  FutureResult<Unit> rejectTimeCorrection(
    String id, {
    required String note,
    String? stepId,
  }) => guard(() async {
    await _remote.rejectTimeCorrection(id, note: note, stepId: stepId);
    return Unit.instance;
  });

  @override
  FutureResult<Uint8List> timeCorrectionAttachment(String url) =>
      guard(() => _remote.fetchFile(url));
}
