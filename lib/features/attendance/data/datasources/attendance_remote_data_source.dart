import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_request.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_request.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/clock_request_model.dart';
import '../models/punch_receipt_model.dart';
import '../models/time_correction_detail_model.dart';
import '../models/time_correction_record_model.dart';
import '../models/time_correction_request_model.dart';
import 'attendance_api_paths.dart';

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

  /// Today's record, or [AttendanceDay.empty] when nothing is punched yet.
  Future<AttendanceDay> todayRecord();

  /// The history page's daily list over [range], newest first.
  Future<List<AttendanceDay>> records(DateRange range);

  /// The history page's stat cards over [range].
  Future<AttendanceSummary> summary(DateRange range);

  /// Files a time-correction request. The created record isn't used, so the
  /// response body is not read.
  Future<void> submitTimeCorrection(TimeCorrectionRequest request);

  /// The employee's own time-correction requests, newest first.
  Future<List<TimeCorrectionRecord>> myTimeCorrections();

  /// One of the employee's requests in full.
  Future<TimeCorrectionDetail> timeCorrectionDetail(String id);

  /// Withdraws a pending request. The body isn't read.
  Future<void> cancelTimeCorrection(String id);

  /// Downloads an evidence file from its storage URL.
  Future<Uint8List> fetchFile(String url);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  /// The history page shows one unpaged list; corrections are limited to
  /// the last 90 days, so this comfortably covers them.
  static const int _correctionPageSize = 100;

  final ApiClient _client;

  /// For evidence files: they live on the object store, not the API, so they
  /// are fetched without the API client's session token.
  final Dio _files;

  AttendanceRemoteDataSourceImpl(this._client, {Dio? files})
    : _files = files ?? Dio();

  @override
  Future<PunchOutcome> clockIn(PunchRequest request) =>
      _punch(AttendancePaths.clockIn, request);

  @override
  Future<PunchOutcome> clockOut(PunchRequest request) =>
      _punch(AttendancePaths.clockOut, request);

  /// Read from the same `month` query the history page uses — the param
  /// `records/my` is known to honour — then narrowed to today's record by
  /// its `date`, so the card and the history list always agree. A record
  /// with no `date` can't be placed in the month, so it is skipped.
  @override
  Future<AttendanceDay> todayRecord() async {
    final now = DateTime.now();
    final today = _isoDate(now);

    final days = await records(DateRange.month(now));
    for (final day in days) {
      final date = day.date;
      if (date != null && _isoDate(date) == today) return day;
    }
    return AttendanceDay.empty;
  }

  @override
  Future<List<AttendanceDay>> records(DateRange range) async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myRecords,
      queryParameters: {
        'month': _isoMonth(range.start),
        'page': 1,
        // Max per the spec (§6.2) — a calendar month never has more days
        // than this, so one page is always the whole range.
        'per_page': 100,
      },
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
    final response = await _client.get<dynamic>(
      AttendancePaths.mySummary,
      queryParameters: {'month': _isoMonth(range.start)},
    );

    return AttendanceSummaryModel.fromJson(
      ApiEnvelope.unwrapObject(response.data),
    );
  }

  @override
  Future<void> submitTimeCorrection(TimeCorrectionRequest request) async {
    final body = TimeCorrectionRequestModel(request).toJson();
    _debugLog('POST ${AttendancePaths.correctionRequests} body', body);

    try {
      final response = await _client.post<dynamic>(
        AttendancePaths.correctionRequests,
        data: body,
      );
      _debugLog('response ${response.statusCode}', response.data);
    } on DioException catch (error) {
      _debugLog('error ${error.response?.statusCode}', error.response?.data);
      rethrow;
    }
  }

  @override
  Future<List<TimeCorrectionRecord>> myTimeCorrections() async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myCorrectionRequests,
      queryParameters: {'page': 1, 'per_page': _correctionPageSize},
    );
    _debugLog(
      'GET ${AttendancePaths.myCorrectionRequests} response',
      response.data,
    );

    final records = ApiEnvelope.unwrapList(response.data)
        .map(TimeCorrectionRecordModel.fromJson)
        .whereType<TimeCorrectionRecord>()
        .toList();
    records.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return records;
  }

  @override
  Future<TimeCorrectionDetail> timeCorrectionDetail(String id) async {
    final path = AttendancePaths.correctionRequest(id);
    final response = await _client.get<dynamic>(path);
    _debugLog('GET $path response', response.data);

    return TimeCorrectionDetailModel.fromJson(
      ApiEnvelope.unwrapObject(response.data),
    );
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
      rethrow;
    }
  }

  @override
  Future<Uint8List> fetchFile(String url) async {
    final response = await _files.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
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
  };

  /// Lifts `error.details` out of the envelope. §7 rule 7 asks for these to
  /// be shown instead of generic copy, so they are parsed rather than dropped.
  static PunchBlockDetails _detailsOf(dynamic body) {
    if (body is! Map) return PunchBlockDetails.empty;

    final error = body['error'];
    if (error is! Map) return PunchBlockDetails.empty;

    final details = error['details'];
    if (details is! Map) return PunchBlockDetails.empty;

    final raw = Map<String, dynamic>.from(details);

    return PunchBlockDetails(
      sessionLabel: _text(raw['session_label']),
      sessionOrder: (raw['session_order'] as num?)?.toInt(),
      earliestCheckout: _text(raw['earliest_checkout']),
      latestCheckout: _text(raw['latest_checkout']),
      // §5.2 spells this `next_session_*`; both spellings seen in the wild.
      nextSessionStart: _text(
        raw['next_session_start'] ?? raw['next_session_starts'],
      ),
      lastShiftEnd: _text(raw['last_shift_end']),
      endedAt: _text(raw['ended_at']),
      nextStarts: _text(raw['next_starts']),
      employeeId: _text(raw['employee_id']),
      raw: raw,
    );
  }

  /// Details values are interpolated straight into user copy, so a number or
  /// a timestamp is accepted as readily as a string.
  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// `YYYY-MM-DD` in the device's own timezone.
  ///
  /// Formatted by hand rather than through `DateFormat`, which would render
  /// the digits in the active locale's numerals — Lao digits would make the
  /// query string unparseable to the backend.
  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// `YYYY-MM`, for the `month` query param on the records and summary
  /// endpoints.
  static String _isoMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
