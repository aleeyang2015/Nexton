import '../../../../core/utils/result.dart';
import '../entities/attendance_day.dart';
import '../entities/attendance_summary.dart';
import '../entities/date_range.dart';
import '../entities/punch_outcome.dart';
import '../entities/punch_request.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
///
/// Both punch methods answer `Result<PunchOutcome>`, which splits two things
/// the spec is careful to keep apart: a `Result.failure` means the request
/// never got a verdict (offline, 5xx, expired session, throttled), while a
/// `Result.success` carrying [PunchBlocked] means the backend understood the
/// punch and refused it for a business reason.
abstract class AttendanceRepository {
  /// `POST /attendance/clock-in`.
  FutureResult<PunchOutcome> clockIn(PunchRequest request);

  /// `POST /attendance/clock-out`.
  FutureResult<PunchOutcome> clockOut(PunchRequest request);

  /// Today's record from `GET /attendance/records/my`, so the UI knows which
  /// punch is owed next without waiting for the user to guess (§6.2).
  ///
  /// A day with no punches yet is [AttendanceDay.empty], not a failure.
  FutureResult<AttendanceDay> todayRecord();

  /// `GET /attendance/records/my` over [range], newest first — the history
  /// page's daily list (§6.2).
  FutureResult<List<AttendanceDay>> records(DateRange range);

  /// `GET /attendance/records/summary/my` over [range] — the history page's
  /// stat cards (§6.3).
  FutureResult<AttendanceSummary> summary(DateRange range);
}
