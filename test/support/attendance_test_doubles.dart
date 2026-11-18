import 'dart:async';
import 'dart:typed_data';

import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/open_ot_session.dart';
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

  /// The open OT clock-in (`ot-sessions/open`); none by default.
  Result<OpenOtSession?> openOt = const Result.success(null);

  /// How many times the open OT session was asked for.
  int openOtCalls = 0;

  /// When set, the next `todayRecord()` / `openOtSession()` waits for it
  /// (taken by the call that sees it). Its answer is the one set when the
  /// call was made.
  Completer<void>? holdToday;
  Completer<void>? holdOpenOt;
  final List<PunchRequest> clockInRequests = [];
  final List<PunchRequest> clockOutRequests = [];
  final List<DateRange> recordsRanges = [];
  final List<DateRange> summaryRanges = [];

  @override
  FutureResult<AttendanceDay> todayRecord() async {
    todayCalls++;
    final answer = today;
    final hold = holdToday;
    holdToday = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OpenOtSession?> openOtSession() async {
    openOtCalls++;
    final answer = openOt;
    final hold = holdOpenOt;
    holdOpenOt = null;
    await hold?.future;
    return answer;
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

  /// The submit's answer: the new request's id by default.
  Result<String?> timeCorrectionResult = const Result.success('tc-new');
  final List<TimeCorrectionRequest> timeCorrectionRequests = [];

  @override
  FutureResult<String?> submitTimeCorrection(
    TimeCorrectionRequest request,
  ) async {
    timeCorrectionRequests.add(request);
    final answer = timeCorrectionResult;
    final hold = holdTimeCorrection;
    holdTimeCorrection = null;
    await hold?.future;
    return answer;
  }

  /// When set, the next correction submit waits for it.
  Completer<void>? holdTimeCorrection;

  /// Answers to `correction-requests/my`, one per call in order; the last
  /// one repeats. One empty page by default.
  List<Result<CursorPage<TimeCorrectionRecord>>> timeCorrectionHistoryResults =
      [const Result.success(CursorPage.single([]))];

  /// What each call asked for, in order.
  final List<({TimeCorrectionStatus? status, String? cursor})>
  timeCorrectionHistoryCalls = [];

  @override
  FutureResult<CursorPage<TimeCorrectionRecord>> myTimeCorrections({
    TimeCorrectionStatus? status,
    String? cursor,
  }) async {
    timeCorrectionHistoryCalls.add((status: status, cursor: cursor));
    final i = timeCorrectionHistoryCalls.length - 1;
    final answers = timeCorrectionHistoryResults;
    return answers[i < answers.length ? i : answers.length - 1];
  }

  /// Answers to `correction-requests/:id`, one per call in order; the last
  /// one repeats.
  List<Result<TimeCorrectionDetail>> timeCorrectionDetailResults = const [
    Result.failure(Failure.unknown(message: 'unset')),
  ];
  final List<String> timeCorrectionDetailCalls = [];

  @override
  FutureResult<TimeCorrectionDetail> timeCorrectionDetail(String id) async {
    timeCorrectionDetailCalls.add(id);
    final i = timeCorrectionDetailCalls.length - 1;
    final answers = timeCorrectionDetailResults;
    return answers[i < answers.length ? i : answers.length - 1];
  }

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
/// Defaults to an empty history and approvals inbox and a decision that goes
/// through, so a test that only cares about one of them can leave the rest
/// alone.
class FakeOffsiteRepository implements OffsiteRepository {
  Result<List<OffsiteRequestDetail>> mineResult = const Result.success([]);
  Result<List<OffsiteRequestDetail>> approvalsResult = const Result.success([]);
  Result<OffsiteOutcome>? submitResult;
  Result<Unit> decisionResult = const Result.success(Unit.instance);

  final List<OffsiteRequest> submitted = [];
  Result<Unit> cancelResult = const Result.success(Unit.instance);

  final List<String> cancelled = [];
  int mineCalls = 0;
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

  /// Answers `waiting(month:)`; the months asked for are kept.
  Result<List<OffsiteRequestDetail>> waitingResult = const Result.success([]);
  final List<String> waitingMonths = [];

  /// When set, the next `waiting` waits for it.
  Completer<void>? holdWaiting;

  @override
  FutureResult<List<OffsiteRequestDetail>> waiting({
    required String month,
  }) async {
    waitingMonths.add(month);
    final answer = waitingResult;
    final hold = holdWaiting;
    holdWaiting = null;
    await hold?.future;
    return answer;
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

  @override
  FutureResult<Unit> cancel(String id) async {
    cancelled.add(id);
    return cancelResult;
  }

  /// "My requests": the pages answered in order (the last one again after
  /// that); by default [mineResult]'s rows as one page. Each call is kept.
  List<Result<CursorPage<OffsiteRequestDetail>>>? myRequestsPages;
  final List<({TimeCorrectionStatus? status, String? cursor})> myRequestsCalls =
      [];

  @override
  FutureResult<CursorPage<OffsiteRequestDetail>> myRequests({
    TimeCorrectionStatus? status,
    String? cursor,
  }) async {
    myRequestsCalls.add((status: status, cursor: cursor));
    final pages = myRequestsPages;
    if (pages == null || pages.isEmpty) {
      return mineResult.mapData(CursorPage.single);
    }
    return pages[(myRequestsCalls.length - 1).clamp(0, pages.length - 1)];
  }

  /// One request by id: [detailResults] in order (the last one again after
  /// that); each id asked for is kept.
  List<Result<OffsiteRequestDetail>> detailResults = [];
  final List<String> detailCalls = [];

  @override
  FutureResult<OffsiteRequestDetail> detail(String id) async {
    detailCalls.add(id);
    return detailResults[(detailCalls.length - 1).clamp(
      0,
      detailResults.length - 1,
    )];
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

  /// When set, the next read waits for it (a slow GPS fix).
  Completer<void>? hold;

  @override
  Future<PunchLocationReading> read(ClockMethod method) async {
    reads.add(method);
    final h = hold;
    hold = null;
    await h?.future;
    if (error != null) throw error!;
    return reading;
  }
}

/// An off-site scan of the caller's, as `offsite-requests/my` lists it:
/// waiting by default, session 1, scanned at [at].
OffsiteRequestDetail waitingOffsite({
  required OffsiteMethod method,
  required DateTime at,
  String id = 'off-1',
  int sessionOrder = 1,
  TimeCorrectionStatus status = TimeCorrectionStatus.pending,
  TimeCorrectionShift? shift,
  DateTime? submittedAt,
  bool noScanTime = false,
}) => OffsiteRequestDetail(
  id: id,
  employee: const TimeCorrectionEmployee(name: 'Somchai'),
  method: method,
  latitude: 17.9757,
  longitude: 102.6331,
  scanTimestamp: noScanTime ? null : at,
  scanDate: DateTime(at.year, at.month, at.day),
  sessionOrder: sessionOrder,
  shift: shift,
  attachmentUrl: 'https://files.nexton.work/uploads/shop.jpg',
  reason: 'Client visit',
  status: status,
  currentStepNo: 1,
  attendanceRecordId: null,
  steps: const [],
  submittedAt: submittedAt ?? at,
);

/// A night shift, 22:00 to 06:00: it crosses midnight.
const nightShift = TimeCorrectionShift(
  start: Duration(hours: 22),
  end: Duration(hours: 6),
);

/// A day shift, 08:00 to 17:00.
const dayShift = TimeCorrectionShift(
  start: Duration(hours: 8),
  end: Duration(hours: 17),
);
