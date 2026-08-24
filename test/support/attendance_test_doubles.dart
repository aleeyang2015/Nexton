import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
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

  Result<PunchOutcome>? clockInResult;
  Result<PunchOutcome>? clockOutResult;

  int todayCalls = 0;
  final List<PunchRequest> clockInRequests = [];
  final List<PunchRequest> clockOutRequests = [];

  @override
  FutureResult<AttendanceDay> todayRecord() async {
    todayCalls++;
    return today;
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
