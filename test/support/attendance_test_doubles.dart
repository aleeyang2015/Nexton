import 'dart:async';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_request.dart';
import 'package:next_on/features/attendance/domain/repositories/attendance_repository.dart';

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
  Result<AttendanceSummary> monthSummary =
      const Result.success(AttendanceSummary.empty);

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
