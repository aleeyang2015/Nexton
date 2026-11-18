import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/paged_list.dart';
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
import '../models/open_ot_session_model.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/clock_request_model.dart';
import '../models/punch_block_details_model.dart';
import '../models/punch_receipt_model.dart';
import '../models/time_correction_detail_model.dart';
import '../models/time_correction_parse.dart';
import '../models/time_correction_record_model.dart';
import '../models/time_correction_request_model.dart';
import 'attendance_api_paths.dart';
import 'correction_error_code.dart';
import 'time_correction_error_code.dart';

/// The attendance calls the home screen can trigger.
///
/// Punches answer a [PunchOutcome] rather than throwing on a business
/// refusal, because a 409 from these endpoints is a normal answer — "you
/// already clocked in", "that needs a reason" — not a failed request. Only
/// genuine failures (offline, 401, 5xx, throttled) leave as exceptions, for
/// the repository to turn into a `Result.failure`.
abstract class AttendanceRemoteDataSource {
  Future<PunchOutcome> clockIn(PunchRequest request);

  Future<PunchOutcome> clockOut(PunchRequest request);

  /// The record the home card is about right now — usually today's, but see
  /// [AttendanceDay.pickCurrent] — or [AttendanceDay.empty] when nothing is
  /// punched yet.
  Future<AttendanceDay> todayRecord();

  /// The user's own open OT clock-in, or null when there is none.
  Future<OpenOtSession?> openOtSession();

  /// The history page's daily list over [range], newest first.
  Future<List<AttendanceDay>> records(DateRange range);

  /// The history page's stat cards over [range].
  Future<AttendanceSummary> summary(DateRange range);

  /// Files a time-correction request. Resolves to the new request's id from
  /// the 201's `data.id` (#45: "View" opens it), or null when the answer
  /// carries none.
  Future<String?> submitTimeCorrection(TimeCorrectionRequest request);

  /// One page of the employee's own time-correction requests (#45):
  /// `GET correction-requests/my?status=&limit=&cursor=`, in the server's
  /// order. [status] is a server filter; null asks for every status.
  Future<CursorPage<TimeCorrectionRecord>> myTimeCorrections({
    TimeCorrectionStatus? status,
    String? cursor,
  });

  /// One request in full. A 404 (gone, or not the caller's to see) is
  /// `CorrectionErrorCode.tokenRequestGone`.
  Future<TimeCorrectionDetail> timeCorrectionDetail(String id);

  /// Withdraws a pending request. The body isn't read. `CANNOT_CANCEL` (not
  /// the caller's, or decided meanwhile) is
  /// `CorrectionErrorCode.tokenCannotCancel`.
  Future<void> cancelTimeCorrection(String id);

  /// The requests the signed-in approver decides on, newest first — the
  /// endpoint scopes to the caller, so a non-approver gets an empty list.
  ///
  /// [status] is passed straight to the endpoint, which reads it against the
  /// caller's own step rather than the request as a whole (§4.4):
  /// `pending` is what still waits on *this* approver, `approved`/`rejected`
  /// what they have already decided. That distinction can't be made on the
  /// client — a request this approver cleared stays `pending` overall while
  /// it sits with HR — so the filter belongs on the query.
  Future<List<TimeCorrectionDetail>> timeCorrectionApprovals({
    TimeCorrectionStatus? status,
  });

  /// Approves the request's current step. [stepId] is the step the caller
  /// saw pending; the backend refuses with `STEP_CHANGED` when it has moved
  /// on since. The body isn't read.
  Future<void> approveTimeCorrection(String id, {String? stepId});

  /// Rejects a pending request. [note] is required by the endpoint — it is
  /// what the employee is told. The body isn't read.
  Future<void> rejectTimeCorrection(
    String id, {
    required String note,
    String? stepId,
  });

  /// Downloads an evidence file from its storage URL.
  Future<Uint8List> fetchFile(String url);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  /// The approvals page shows one unpaged list; corrections are limited to
  /// the last 30 days, so this comfortably covers them.
  static const int _correctionPageSize = 100;

  /// Rows per page of "My requests"' "forgot to scan" tab (#45), as the
  /// off-site tab asks for.
  static const int myCorrectionsPageSize = 20;

  /// Rows asked for per month when looking for the current record. `records/my`
  /// answers newest first, so the first few rows of a month hold yesterday,
  /// today and tomorrow — unless the month has rows dated later than that, in
  /// which case [_rowsAround] reads the whole month instead.
  static const int _currentRecordPageSize = 5;

  /// Max per the spec (§6.2) — a calendar month never has more days than
  /// this, so one page is always the whole month.
  static const int _monthPageSize = 100;

  final ApiClient _client;

  /// The time, injected so a test can stand on the last day of a month.
  final DateTime Function() _now;

  /// For evidence files: they live on the object store, not the API, so they
  /// are fetched without the API client's session token.
  final Dio _files;

  AttendanceRemoteDataSourceImpl(
    this._client, {
    Dio? files,
    DateTime Function() now = DateTime.now,
  }) : _files = files ?? Dio(),
       _now = now;

  @override
  Future<PunchOutcome> clockIn(PunchRequest request) =>
      _punch(AttendancePaths.clockIn, request);

  @override
  Future<PunchOutcome> clockOut(PunchRequest request) =>
      _punch(AttendancePaths.clockOut, request);

  /// Read from the same `month` query the history page uses, so the card and
  /// the history list always agree.
  ///
  /// The record for "now" can be dated yesterday (a night shift still
  /// running) or tomorrow (a 23:50 punch for a 00:00 shift), so the newest
  /// rows of each month those three days fall in are read — one call on most
  /// days, two on the first or last day of a month, in parallel — and
  /// [AttendanceDay.pickCurrent] chooses among them.
  @override
  Future<AttendanceDay> todayRecord() async {
    final now = _now();

    // The earliest of the three days in each month they fall in: the day a
    // page of that month has to reach back to.
    final earliestByMonth = <String, DateTime>{};
    for (final offset in const [-1, 0, 1]) {
      final day = DateTime(now.year, now.month, now.day + offset);
      earliestByMonth.putIfAbsent(_isoMonth(day), () => day);
    }

    final pages = await Future.wait([
      for (final MapEntry(key: month, value: earliest)
          in earliestByMonth.entries)
        _rowsAround(month, reachingBackTo: earliest),
    ]);

    return AttendanceDay.pickCurrent([
      for (final page in pages) ...page,
    ], now);
  }

  /// `"data": null` (no open OT clock-in) is null here. It is checked before
  /// [ApiEnvelope.unwrapObject], which would hand back the envelope itself.
  @override
  Future<OpenOtSession?> openOtSession() async {
    final response = await _client.get<dynamic>(AttendancePaths.openOtSession);
    final body = response.data;
    if (body is Map && body['data'] == null && body['success'] == true) {
      return null;
    }
    return OpenOtSessionModel.fromJson(ApiEnvelope.unwrapObject(body));
  }

  /// The newest rows of [month], enough to hold every day from
  /// [reachingBackTo] on.
  ///
  /// The short page is enough when the month's newest rows are the days
  /// around now. If it comes back full and still has not reached
  /// [reachingBackTo] (the month holds rows dated later than tomorrow), the
  /// days wanted may lie beyond it, so the whole month is read: a card that
  /// missed today's record would offer the wrong punch.
  Future<List<AttendanceDay>> _rowsAround(
    String month, {
    required DateTime reachingBackTo,
  }) async {
    final page = await _recordsOf(month, perPage: _currentRecordPageSize);
    if (page.length < _currentRecordPageSize) return page;

    final reached = page.any((row) {
      final date = row.date;
      return date != null && !date.isAfter(reachingBackTo);
    });
    if (reached) return page;

    return _recordsOf(month, perPage: _monthPageSize);
  }

  @override
  Future<List<AttendanceDay>> records(DateRange range) {
    assert(_isOneMonth(range), 'records() reads one month, got $range');
    return _recordsOf(_isoMonth(range.start), perPage: _monthPageSize);
  }

  /// One page of `records/my` for [month] (`YYYY-MM`), newest first.
  Future<List<AttendanceDay>> _recordsOf(
    String month, {
    required int perPage,
  }) async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myRecords,
      queryParameters: {'month': month, 'page': 1, 'per_page': perPage},
    );

    final days = ApiEnvelope.unwrapList(
      response.data,
    ).map(AttendanceRecordModel.fromJson).toList();

    days.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    return days;
  }

  @override
  Future<AttendanceSummary> summary(DateRange range) async {
    assert(_isOneMonth(range), 'summary() reads one month, got $range');
    final response = await _client.get<dynamic>(
      AttendancePaths.mySummary,
      queryParameters: {'month': _isoMonth(range.start)},
    );

    return AttendanceSummaryModel.fromJson(
      ApiEnvelope.unwrapObject(response.data),
    );
  }

  @override
  Future<String?> submitTimeCorrection(TimeCorrectionRequest request) async {
    final body = TimeCorrectionRequestModel(request).toJson();
    _debugLog('POST ${AttendancePaths.correctionRequests} body', body);

    try {
      final response = await _client.post<dynamic>(
        AttendancePaths.correctionRequests,
        data: body,
      );
      _debugLog('response ${response.statusCode}', response.data);
      // The request went in either way: an answer without a usable id only
      // means there is nothing for "View" to open.
      final data = response.data;
      final created = data is Map && data['data'] is Map
          ? data['data'] as Map
          : null;
      return created == null ? null : TimeCorrectionJson.text(created['id']);
    } on DioException catch (error) {
      _debugLog('error ${error.response?.statusCode}', error.response?.data);
      // A refusal the user can act on, in plain words (#43).
      final refusal = CorrectionErrorCode.fromResponse(error);
      if (refusal != null) throw refusal;
      rethrow;
    }
  }

  @override
  Future<CursorPage<TimeCorrectionRecord>> myTimeCorrections({
    TimeCorrectionStatus? status,
    String? cursor,
  }) async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myCorrectionRequests,
      queryParameters: {
        if (status != null) 'status': status.wireValue,
        'limit': myCorrectionsPageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    _debugLog(
      'GET ${AttendancePaths.myCorrectionRequests} response',
      response.data,
    );

    // Kept in the server's order: re-sorting one page would put its rows out
    // of step with the next page's (keyset paging).
    final page = CursorPage.fromBody<TimeCorrectionRecord?>(
      response.data,
      TimeCorrectionRecordModel.fromJson,
    );
    return CursorPage(
      items: page.items.whereType<TimeCorrectionRecord>().toList(),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<TimeCorrectionDetail> timeCorrectionDetail(String id) async {
    final path = AttendancePaths.correctionRequest(id);
    try {
      final response = await _client.get<dynamic>(path);
      _debugLog('GET $path response', response.data);

      return TimeCorrectionDetailModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    } on DioException catch (error) {
      // Gone, or not the caller's to see: #37's "not available", no Retry.
      if (error.response?.statusCode == 404) {
        throw const Failure.validation(
          message: CorrectionErrorCode.tokenRequestGone,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelTimeCorrection(String id) async {
    final path = AttendancePaths.cancelCorrectionRequest(id);
    try {
      final response = await _client.put<dynamic>(path);
      _debugLog('PUT $path response ${response.statusCode}', response.data);
    } on DioException catch (error) {
      _debugLog(
        'PUT $path error ${error.response?.statusCode}',
        error.response?.data,
      );
      // By its code, not its status: not the caller's, or no longer pending.
      final code = ApiError.tryParse(error.response?.data)?.code;
      if (code == CorrectionErrorCode.cannotCancel) {
        throw Failure.validation(
          message: CorrectionErrorCode.tokenCannotCancel,
          code: code,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<TimeCorrectionDetail>> timeCorrectionApprovals({
    TimeCorrectionStatus? status,
  }) async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myCorrectionApprovals,
      queryParameters: {
        if (status != null) 'status': status.wireValue,
        'page': 1,
        'per_page': _correctionPageSize,
      },
    );
    _debugLog(
      'GET ${AttendancePaths.myCorrectionApprovals} response',
      response.data,
    );

    final requests = ApiEnvelope.unwrapList(
      response.data,
    ).map(_approvalOrNull).whereType<TimeCorrectionDetail>().toList();
    requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return requests;
  }

  @override
  Future<void> approveTimeCorrection(String id, {String? stepId}) => _decide(
    AttendancePaths.approveCorrectionRequest(id),
    {if (stepId != null) 'step_id': stepId},
  );

  /// §4.8 names the rejection reason `note`, and rejects the call with a 422
  /// without it.
  @override
  Future<void> rejectTimeCorrection(
    String id, {
    required String note,
    String? stepId,
  }) => _decide(AttendancePaths.rejectCorrectionRequest(id), {
    'note': note.trim(),
    if (stepId != null) 'step_id': stepId,
  });

  @override
  Future<Uint8List> fetchFile(String url) async {
    final response = await _files.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// An approval-list entry carries the same fields as the detail response;
  /// one missing its id, date or type is dropped rather than shown
  /// half-empty — same policy as [TimeCorrectionRecordModel].
  static TimeCorrectionDetail? _approvalOrNull(Map<String, dynamic> json) {
    try {
      return TimeCorrectionDetailModel.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// `PUT` an approver's decision, logging the answer either way.
  ///
  /// A refusal the spec documents (§6) leaves as a
  /// `Failure.validation(message: <token>)` the localizer can translate —
  /// the same contract `LeaveRemoteDataSourceImpl._business` uses. Anything
  /// else rethrows for the repository to map.
  Future<void> _decide(String path, Map<String, dynamic> body) async {
    _debugLog('PUT $path body', body);
    try {
      final response = await _client.put<dynamic>(path, data: body);
      _debugLog('PUT $path response ${response.statusCode}', response.data);
    } on DioException catch (error) {
      _debugLog(
        'PUT $path error ${error.response?.statusCode}',
        error.response?.data,
      );

      final code = ApiError.tryParse(error.response?.data)?.code;
      final token = TimeCorrectionErrorCode.tokenByWire[code];
      if (token != null) throw Failure.validation(message: token);
      rethrow;
    }
  }

  /// Pretty-prints a time-correction payload under one tag, so it can be
  /// found among the client's general request log. Debug builds only — the
  /// body carries the employee's reason and evidence URL.
  static void _debugLog(String label, Object? data) {
    if (!kDebugMode) return;
    final text = data is Map || data is List
        ? const JsonEncoder.withIndent('  ').convert(data)
        : '$data';
    debugPrint('[TimeCorrection] $label:\n$text', wrapWidth: 1024);
  }

  /// A 200 here still needs its body read: §3 warns that `status` — not the
  /// HTTP code — says whether the punch passed its location check.
  Future<PunchOutcome> _punch(String path, PunchRequest request) async {
    try {
      final response = await _client.post<dynamic>(
        path,
        data: ClockRequestModel(request).toJson(),
      );

      return PunchRecorded(
        PunchReceiptModel.fromJson(ApiEnvelope.unwrapObject(response.data)),
      );
    } on DioException catch (error) {
      final blocked = _asBlocked(error);
      if (blocked != null) return blocked;
      // Not a business rule — let the repository map it to a Failure.
      rethrow;
    }
  }

  /// Recognises the refusals from §5.1/§5.2 that the user can respond to.
  ///
  /// Returns null for everything else — an unknown code, a 5xx, an expired
  /// session — so an unrecognised answer is never dressed up as a rule the
  /// app claims to understand.
  PunchBlocked? _asBlocked(DioException error) {
    final response = error.response;
    final apiError = ApiError.tryParse(response?.data);
    final rule = _rules[apiError?.code];
    if (rule == null) return null;

    // Guard against a code that only *looks* familiar: the documented
    // refusals arrive as 400, 403 or 409, never as a server fault.
    final status = response?.statusCode;
    if (status == null || status >= 500) return null;

    // The user is shown the app's own text for the rule, so the server's
    // sentence would otherwise be seen by nobody. It names the session and
    // the times; a developer chasing a refusal wants it.
    _debugLog('punch refused (${apiError?.code})', {
      'message': apiError?.bestMessage,
      'details': _detailsOf(response?.data).raw,
    });

    return PunchBlocked(
      rule: rule,
      message: apiError?.bestMessage ?? '',
      details: _detailsOf(response?.data),
    );
  }

  /// §5's rule: branch on `error.code`, never on `message`, which is free to
  /// change without notice.
  static const Map<String, AttendanceRule> _rules = {
    'MOCK_LOCATION_DETECTED': AttendanceRule.mockLocationDetected,
    'EMPLOYEE_NOT_FOUND': AttendanceRule.employeeNotFound,
    'NO_SHIFT_ASSIGNED': AttendanceRule.noShiftAssigned,
    'OUTSIDE_SHIFT_HOURS': AttendanceRule.outsideShiftHours,
    'OVERNIGHT_SESSION_DONE': AttendanceRule.overnightSessionDone,
    'SESSION_ALREADY_STARTED': AttendanceRule.sessionAlreadyStarted,
    'SESSION_ALREADY_COMPLETED': AttendanceRule.sessionAlreadyCompleted,
    'SESSION_ALREADY_CHECKED_OUT': AttendanceRule.sessionAlreadyCheckedOut,
    'SESSION_NOT_STARTED': AttendanceRule.sessionNotStarted,
    'AFTER_CHECKOUT_WINDOW': AttendanceRule.afterCheckoutWindow,
    'EARLY_CHECKOUT_REQUIRES_REASON':
        AttendanceRule.earlyCheckoutRequiresReason,
    // Undocumented: §3 describes out-of-area as a *stored* punch — 200 with
    // `rejection_reason: "outside_geofence"` — but the deployed API refuses
    // it, promoting that reason to an error code and omitting `data`, so
    // nothing is written. Both shapes are handled; whichever the backend
    // settles on, the employee is offered the off-site scan request.
    'OUTSIDE_GEOFENCE': AttendanceRule.outsideWorkArea,
    'TOO_EARLY_CHECKIN': AttendanceRule.tooEarlyCheckin,
    'CLOCK_OUT_BEFORE_CLOCK_IN': AttendanceRule.clockOutBeforeClockIn,
    'OT_CHANGED': AttendanceRule.otChanged,
    // A clock-out whose off-site check-in still waits for its approvers.
    'CHECKIN_PENDING_APPROVAL': AttendanceRule.checkinPendingApproval,
  };

  /// Lifts `error.details` out of the envelope — shared with the off-site
  /// scan request, which the same session guard refuses with the same details.
  static PunchBlockDetails _detailsOf(dynamic body) =>
      PunchBlockDetailsModel.fromErrorBody(body);

  /// The endpoints read a range as its start's month, so a range that
  /// spans two would silently lose the second.
  static bool _isOneMonth(DateRange range) =>
      range.start.year == range.end.year &&
      range.start.month == range.end.month;

  /// `YYYY-MM` in the device's own timezone, for the `month` query param on
  /// the records and summary endpoints.
  ///
  /// Formatted by hand rather than through `DateFormat`, which would render
  /// the digits in the active locale's numerals — Lao digits would make the
  /// query string unparseable to the backend.
  static String _isoMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
