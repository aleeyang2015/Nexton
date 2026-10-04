import 'dart:async';
import 'dart:typed_data';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_request.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_request.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_record.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:next_on/features/attendance/domain/repositories/offsite_repository.dart';

/// Programmable attendance repository: each call returns the queued result
/// and records the request it was given.
///
/// Defaults to an untouched day and a verified punch, so a test that only
/// cares about something else can install it and ignore it — which is what
/// the router tests do, since the home screen now loads today's record on
/// sight and would otherwise reach for the real network stack.
class FakeAttendanceRepository implements AttendanceRepository {
  Result<AttendanceDay> today = const Result.success(AttendanceDay.empty);
  Result<List<AttendanceDay>> monthRecords = const Result.success([]);
  Result<AttendanceSummary> monthSummary = const Result.success(
    AttendanceSummary.empty,
  );

  /// Reproduces the real backend's observed behaviour on `records/summary/
  /// my`: the request never resolves into a response or a `DioException` —
  /// so `summary()` never completes at all, rather than answering
  /// [monthSummary].
  bool hangSummary = false;

  Result<PunchOutcome>? clockInResult;
  Result<PunchOutcome>? clockOutResult;

  int todayCalls = 0;
  final List<PunchRequest> clockInRequests = [];
  final List<PunchRequest> clockOutRequests = [];
  final List<DateRange> recordsRanges = [];
  final List<DateRange> summaryRanges = [];

  @override
  FutureResult<AttendanceDay> todayRecord() async {
    todayCalls++;
    return today;
  }

  @override
  FutureResult<List<AttendanceDay>> records(DateRange range) async {
    recordsRanges.add(range);
    return monthRecords;
  }

  @override
  FutureResult<AttendanceSummary> summary(DateRange range) {
    summaryRanges.add(range);
    if (hangSummary) return Completer<Result<AttendanceSummary>>().future;
    return Future.value(monthSummary);
  }

  @override
  FutureResult<PunchOutcome> clockIn(PunchRequest request) async {
    clockInRequests.add(request);
    return clockInResult ??
        const Result.failure(Failure.unknown(message: 'no clock-in queued'));
  }

  @override
  FutureResult<PunchOutcome> clockOut(PunchRequest request) async {
    clockOutRequests.add(request);
    return clockOutResult ??
        const Result.failure(Failure.unknown(message: 'no clock-out queued'));
  }

  Result<Unit> timeCorrectionResult = const Result.success(Unit.instance);
  final List<TimeCorrectionRequest> timeCorrectionRequests = [];

  @override
  FutureResult<Unit> submitTimeCorrection(TimeCorrectionRequest request) async {
    timeCorrectionRequests.add(request);
    return timeCorrectionResult;
  }

  Result<List<TimeCorrectionRecord>> timeCorrectionHistoryResult =
      const Result.success([]);

  @override
  FutureResult<List<TimeCorrectionRecord>> myTimeCorrections() async =>
      timeCorrectionHistoryResult;

  Result<TimeCorrectionDetail> timeCorrectionDetailResult =
      const Result.failure(Failure.unknown(message: 'unset'));

  @override
  FutureResult<TimeCorrectionDetail> timeCorrectionDetail(String id) async =>
      timeCorrectionDetailResult;

  Result<Unit> cancelTimeCorrectionResult = const Result.success(Unit.instance);
  final List<String> cancelledTimeCorrectionIds = [];

  @override
  FutureResult<Unit> cancelTimeCorrection(String id) async {
    cancelledTimeCorrectionIds.add(id);
    return cancelTimeCorrectionResult;
  }

  Result<List<TimeCorrectionDetail>> timeCorrectionApprovalsResult =
      const Result.success([]);

  /// The statuses the page asked for, in call order.
  final List<TimeCorrectionStatus?> requestedApprovalStatuses = [];

  @override
  FutureResult<List<TimeCorrectionDetail>> timeCorrectionApprovals({
    TimeCorrectionStatus? status,
  }) async {
    requestedApprovalStatuses.add(status);
    return timeCorrectionApprovalsResult;
  }

  Result<Unit> approveTimeCorrectionResult = const Result.success(
    Unit.instance,
  );
  final List<({String id, String? stepId})> approvedTimeCorrections = [];

  @override
  FutureResult<Unit> approveTimeCorrection(String id, {String? stepId}) async {
    approvedTimeCorrections.add((id: id, stepId: stepId));
    return approveTimeCorrectionResult;
  }

  Result<Unit> rejectTimeCorrectionResult = const Result.success(Unit.instance);
  final List<({String id, String note, String? stepId})>
  rejectedTimeCorrections = [];

  @override
  FutureResult<Unit> rejectTimeCorrection(
    String id, {
    required String note,
    String? stepId,
  }) async {
    rejectedTimeCorrections.add((id: id, note: note, stepId: stepId));
    return rejectTimeCorrectionResult;
  }

  Result<Uint8List> timeCorrectionAttachmentResult = Result.success(
    Uint8List(0),
  );

  @override
  FutureResult<Uint8List> timeCorrectionAttachment(String url) async =>
      timeCorrectionAttachmentResult;
}

/// Programmable off-site scan repository: each call returns the queued result
/// and records what it was asked.
///
/// Defaults to an empty approvals inbox and a decision that goes through, so a
/// test that only cares about one of them can leave the rest alone.
class FakeOffsiteRepository implements OffsiteRepository {
  Result<List<OffsiteRequestDetail>> approvalsResult = const Result.success([]);
  Result<OffsiteOutcome>? submitResult;
  Result<Unit> decisionResult = const Result.success(Unit.instance);

  final List<OffsiteRequest> submitted = [];
  final List<TimeCorrectionStatus?> approvalsStatuses = [];
  final List<({String id, String? stepId})> approved = [];
  final List<({String id, String note, String? stepId})> rejected = [];

  @override
  FutureResult<OffsiteOutcome> submit(OffsiteRequest request) async {
    submitted.add(request);
    return submitResult ??
        const Result.success(
          OffsiteFiled(OffsiteSubmission(autoApproved: true)),
        );
  }

  @override
  FutureResult<List<OffsiteRequestDetail>> approvals({
    TimeCorrectionStatus? status,
  }) async {
    approvalsStatuses.add(status);
    return approvalsResult;
  }

  @override
  FutureResult<Unit> approve(String id, {String? stepId}) async {
    approved.add((id: id, stepId: stepId));
    return decisionResult;
  }

  @override
  FutureResult<Unit> reject(
    String id, {
    required String note,
    String? stepId,
  }) async {
    rejected.add((id: id, note: note, stepId: stepId));
    return decisionResult;
  }
}

/// Location source with a scripted reading, standing in for the device.
class FakePunchLocationSource implements PunchLocationSource {
  PunchLocationReading reading;
  Object? error;

  final List<ClockMethod> reads = [];

  FakePunchLocationSource([
    this.reading = const PunchLocationReading(
      latitude: 17.9757,
      longitude: 102.6331,
      gpsAccuracy: 12.5,
      isMockLocation: false,
    ),
  ]);

  @override
  Future<PunchLocationReading> read(ClockMethod method) async {
    reads.add(method);
    if (error != null) throw error!;
    return reading;
  }
}
