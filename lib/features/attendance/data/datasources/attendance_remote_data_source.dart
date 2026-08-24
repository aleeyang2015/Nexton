import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_request.dart';
import '../models/attendance_record_model.dart';
import '../models/clock_request_model.dart';
import '../models/punch_receipt_model.dart';
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
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  /// Enough to cover a day split into several sessions; the endpoint is
  /// queried for a single date, so one page is always the whole answer.
  static const int _todayPageSize = 5;

  final ApiClient _client;

  AttendanceRemoteDataSourceImpl(this._client);

  @override
  Future<PunchOutcome> clockIn(PunchRequest request) =>
      _punch(AttendancePaths.clockIn, request);

  @override
  Future<PunchOutcome> clockOut(PunchRequest request) =>
      _punch(AttendancePaths.clockOut, request);

  @override
  Future<AttendanceDay> todayRecord() async {
    final today = _isoDate(DateTime.now());

    final response = await _client.get<dynamic>(
      AttendancePaths.myRecords,
      queryParameters: {
        'start_date': today,
        'end_date': today,
        'page': 1,
        'per_page': _todayPageSize,
      },
    );

    final records = ApiEnvelope.unwrapList(response.data);
    if (records.isEmpty) return AttendanceDay.empty;

    return AttendanceRecordModel.fromJson(records.first);
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
}
