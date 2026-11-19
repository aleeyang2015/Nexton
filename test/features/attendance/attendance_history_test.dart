import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/theme/app_colors.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_history_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_history_state.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_history_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// Serves one canned response and records the request that asked for it —
/// same double `attendance_api_test.dart` uses, kept file-local since it's
/// only ever configured for the one call under test.
class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = const <String, dynamic>{};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DateRange.month', () {
    test('spans the 1st to the last day of an ordinary month', () {
      final range = DateRange.month(DateTime(2026, 6, 22));

      expect(range.start, DateTime(2026, 6, 1));
      expect(range.end, DateTime(2026, 6, 30));
    });

    test('crosses the year boundary for December', () {
      final range = DateRange.month(DateTime(2026, 12, 5));

      expect(range.start, DateTime(2026, 12, 1));
      expect(range.end, DateTime(2026, 12, 31));
    });

    test('handles a leap-year February', () {
      final range = DateRange.month(DateTime(2028, 2, 10));

      expect(range.end, DateTime(2028, 2, 29));
    });
  });

  group('AttendanceRemoteDataSourceImpl.records/summary', () {
    late _StubAdapter adapter;
    late AttendanceRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      source = AttendanceRemoteDataSourceImpl(ApiClient(dio: dio));
    });

    final range = DateRange(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 30),
    );

    test('records() queries the month and sorts newest first', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-06-20',
              'sessions': [
                {
                  'clock_in': '2026-06-20T01:00:00Z',
                  'clock_out': '2026-06-20T09:00:00Z',
                  'is_late': true,
                  'late_minutes': 11,
                  'clock_in_method': 'gps',
                  'clock_out_method': 'wifi',
                  'clock_in_location_name': 'Office Center',
                  'clock_out_location_name': 'Warehouse',
                  'shift_detail': {
                    'id': 'sd-am',
                    'name': 'Morning',
                    'name_lo': 'ກະເຊົ້າ',
                    'start_time': '08:00:00',
                    'end_time': '17:00:00',
                  },
                },
              ],
            },
            {
              'date': '2026-06-22',
              'sessions': [
                {
                  'clock_in': '2026-06-22T01:02:00Z',
                  'clock_out': '2026-06-22T10:05:00Z',
                  'is_early_exit': true,
                  'early_exit_minutes': 20,
                },
              ],
            },
          ],
        };

      final days = await source.records(range);

      expect(adapter.lastRequest!.path, contains('/attendance/records/my'));
      expect(adapter.lastRequest!.queryParameters['month'], '2026-06');
      // ASCII digits regardless of the active locale.
      expect(
        adapter.lastRequest!.queryParameters['month'],
        matches(r'^\d{4}-\d{2}$'),
      );

      expect(days, hasLength(2));
      expect(days.first.date, DateTime(2026, 6, 22)); // newest first

      final late = days.last;
      expect(late.isLate, isTrue);
      expect(late.lateMinutes, 11);
      // The clock-in's method and place, when the session has a clock-in.
      expect(late.sessions.single.method, 'gps');
      // Its part's id, for "forgot to scan" from this row (#44).
      expect(late.sessions.single.partId, 'sd-am');
      expect(days.first.sessions.single.partId, isNull);
      expect(late.sessions.single.locationLabel, 'Office Center');
      expect(late.sessions.single.partName, 'Morning');
      expect(late.sessions.single.partNameLo, 'ກະເຊົ້າ');
      expect(late.sessions.single.partStartTime, '08:00:00');

      final earlyExit = days.first;
      expect(earlyExit.isEarlyExit, isTrue);
      expect(earlyExit.earlyExitMinutes, 20);
    });

    test('a session with only a clock-out takes the clock-out\'s method and '
        'place', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-06-19',
              'status': 'absent',
              'work_hours': 0,
              'sessions': [
                {
                  'clock_in': null,
                  'clock_out': '2026-06-19 17:02:00',
                  'clock_in_method': null,
                  'clock_out_method': 'biometric',
                  'clock_in_location_name': null,
                  'clock_out_location_name': 'Head Office',
                  'shift_detail': null,
                },
              ],
            },
          ],
        };

      final day = (await source.records(range)).single;
      final session = day.sessions.single;

      expect(day.status, 'absent');
      expect(session.clockIn, isNull);
      expect(session.method, 'biometric');
      expect(session.locationLabel, 'Head Office');
      // No shift part: the row falls back to its position.
      expect(session.partName, isNull);
      expect(session.partNameLo, isNull);
    });

    test('blank text is no text: it neither names a row nor hides the '
        'clock-out\'s method and place', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-06-16',
              'sessions': [
                {
                  'clock_in': '2026-06-16 08:00:00',
                  'clock_out': '2026-06-16 17:00:00',
                  'clock_in_method': ' ',
                  'clock_out_method': 'gps',
                  'clock_in_location_name': '',
                  'clock_out_location_name': ' Head Office ',
                  'shift_detail': {'name': '  ', 'name_lo': null},
                },
              ],
            },
          ],
        };

      final session = (await source.records(range)).single.sessions.single;

      expect(session.method, 'gps');
      expect(session.locationLabel, 'Head Office');
      expect(session.partName, isNull);
    });

    test('the day\'s hours come from work_hours, and the made-up keys are '
        'not read', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-06-18',
              'work_hours': 7.5,
              'total_work_hours': 99,
              'sessions': [
                {
                  'clock_in_at': '2026-06-18 08:00:00',
                  'session_label': '08:00–12:00',
                  'method': 'gps',
                  'location_name': 'Nowhere',
                  'early_leave_minutes': 30,
                  'is_early_exit': true,
                },
              ],
            },
            {'work_date': '2026-06-17', 'sessions': <dynamic>[]},
          ],
        };

      final days = await source.records(range);
      final dated = days.firstWhere((d) => d.date != null);
      final session = dated.sessions.single;

      expect(dated.totalWorkHours, 7.5);
      expect(session.clockIn, isNull);
      expect(session.method, isNull);
      expect(session.locationLabel, isNull);
      expect(session.partName, isNull);
      expect(session.earlyExitMinutes, isNull);
      // `work_date` is not a key the backend sends.
      expect(days.where((d) => d.date == null), hasLength(1));
    });

    test('the day\'s OT hours are the server\'s overtime_hours, and 0 when it '
        'sends none', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {'date': '2026-06-18', 'work_hours': 9.5, 'overtime_hours': 1.5},
            {'date': '2026-06-17', 'work_hours': 10},
            {'date': '2026-06-16', 'work_hours': 10, 'overtime_hours': null},
          ],
        };

      final days = await source.records(range);

      expect(days.map((d) => d.overtimeHours), [1.5, 0, 0]);
    });

    test('summary() reads all nine numbers the server counts', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'total_working_days': 23,
            'present_days': 15,
            'late_days': 2,
            'half_days': 1,
            'incomplete_days': 3,
            'absent_days': 4,
            'leave_days': 5,
            'total_work_hours': 121.5,
            'total_overtime_hours': 6.5,
            'average_clock_in': '08:03',
          },
        };

      final summary = await source.summary(range);

      expect(
        adapter.lastRequest!.path,
        contains('/attendance/records/summary/my'),
      );
      expect(adapter.lastRequest!.queryParameters, {'month': '2026-06'});
      expect(
        summary,
        const AttendanceSummary(
          totalWorkingDays: 23,
          presentDays: 15,
          lateDays: 2,
          halfDays: 1,
          incompleteDays: 3,
          absentDays: 4,
          leaveDays: 5,
          totalWorkHours: 121.5,
          totalOvertimeHours: 6.5,
        ),
      );
    });

    test('a count the server left out reads as 0', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {'present_days': 15},
        };

      final summary = await source.summary(range);

      expect(summary.presentDays, 15);
      expect(summary.leaveDays, 0);
      expect(summary.totalWorkingDays, 0);
      expect(summary.totalOvertimeHours, 0);
    });
  });

  group('AttendanceHistoryCopy', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final lo = lookupAppLocalizations(const Locale('lo'));

    test('monthYear names the month in each language', () {
      expect(
        AttendanceHistoryCopy.monthYear(en, DateTime(2026, 6)),
        'June 2026',
      );
      expect(
        AttendanceHistoryCopy.monthYear(lo, DateTime(2026, 6)),
        'ມິຖຸນາ 2026',
      );
    });

    test('dayTitle combines the weekday, day and short month', () {
      // 2026-06-22 is a Monday.
      expect(
        AttendanceHistoryCopy.dayTitle(en, DateTime(2026, 6, 22)),
        'Monday 22 Jun',
      );
      expect(
        AttendanceHistoryCopy.dayTitle(lo, DateTime(2026, 6, 22)),
        'ວັນຈັນ 22 ມິ.ຖ.',
      );
    });

    test('on a worked day, a late arrival outranks an early exit', () {
      final day = AttendanceDay(
        status: 'present',
        totalWorkHours: 9.5,
        sessions: [
          AttendanceSession(
            clockIn: DateTime(2026, 6, 22, 8),
            isLate: true,
            lateMinutes: 11,
          ),
          AttendanceSession(
            clockOut: DateTime(2026, 6, 22, 16, 40),
            isEarlyExit: true,
            earlyExitMinutes: 20,
          ),
        ],
      );

      final status = AttendanceHistoryCopy.status(en, day);

      expect(status.label, 'Late by 11 min');
      expect(status.color, AppColors.attendanceLate);
    });

    test('absent: the red pill, even though the day has a punch', () {
      // Lae's day with only a clock-out is stored absent.
      final day = AttendanceDay(
        status: 'absent',
        sessions: [AttendanceSession(clockOut: DateTime(2026, 6, 19, 17, 2))],
      );

      expect(AttendanceHistoryCopy.status(lo, day).label, 'ຂາດວຽກ');
      expect(AttendanceHistoryCopy.status(en, day).label, 'Absent');
      expect(
        AttendanceHistoryCopy.status(en, day).color,
        AppColors.attendanceAbsent,
      );
    });

    test('absent outranks a late flag: late past the absence limit is absent',
        () {
      const day = AttendanceDay(
        status: 'absent',
        sessions: [AttendanceSession(isLate: true, lateMinutes: 130)],
      );

      expect(AttendanceHistoryCopy.status(en, day).label, 'Absent');
    });

    test('incomplete: clocked in but not out', () {
      final day = AttendanceDay(
        status: 'incomplete',
        sessions: [AttendanceSession(clockIn: DateTime(2026, 6, 19, 8))],
      );

      expect(AttendanceHistoryCopy.status(lo, day).label, 'ບໍ່ຄົບ');
      expect(AttendanceHistoryCopy.status(en, day).label, 'Incomplete');
      expect(
        AttendanceHistoryCopy.status(en, day).color,
        AppColors.attendanceLate,
      );
    });

    test('half day', () {
      const day = AttendanceDay(status: 'half_day');

      expect(AttendanceHistoryCopy.status(lo, day).label, 'ເຄິ່ງມື້');
      expect(AttendanceHistoryCopy.status(en, day).label, 'Half day');
      expect(AttendanceHistoryCopy.status(en, day).color, AppColors.gray600);
    });

    test('present or late with a late flag: the late pill, with minutes when '
        'known', () {
      for (final status in const ['present', 'late']) {
        final day = AttendanceDay(
          status: status,
          sessions: const [AttendanceSession(isLate: true, lateMinutes: 11)],
        );

        expect(
          AttendanceHistoryCopy.status(en, day).label,
          'Late by 11 min',
          reason: status,
        );
      }
    });

    test('a day the backend calls late is late, even with no session flag',
        () {
      const day = AttendanceDay(
        status: 'late',
        sessions: [AttendanceSession()],
      );

      final status = AttendanceHistoryCopy.status(en, day);

      expect(status.label, 'Late');
      expect(status.color, AppColors.attendanceLate);
    });

    test('present with an early exit: the early-exit pill', () {
      const day = AttendanceDay(
        status: 'present',
        sessions: [AttendanceSession(isEarlyExit: true, earlyExitMinutes: 20)],
      );

      final status = AttendanceHistoryCopy.status(en, day);

      expect(status.label, 'Left 20 min early');
      expect(status.color, AppColors.gray600);
    });

    test('a missing or unknown status falls back to the flags', () {
      const late = [AttendanceSession(isLate: true)];

      expect(
        AttendanceHistoryCopy.status(en, const AttendanceDay(sessions: late))
            .label,
        'Late',
      );
      expect(
        AttendanceHistoryCopy.status(
          en,
          const AttendanceDay(status: 'a_new_status', sessions: late),
        ).label,
        'Late',
      );
      expect(
        AttendanceHistoryCopy.status(
          en,
          const AttendanceDay(status: 'a_new_status'),
        ).label,
        'Present',
      );
    });

    test('the status is read whatever its case or padding', () {
      expect(
        AttendanceHistoryCopy.status(
          en,
          const AttendanceDay(status: ' Absent '),
        ).label,
        'Absent',
      );
    });

    test('a late day without a minute count still names the status', () {
      final day = AttendanceDay(
        sessions: const [AttendanceSession(isLate: true)],
      );

      expect(AttendanceHistoryCopy.status(en, day).label, 'Late');
    });

    test('a 10-hour present day shows the present pill: no OT is made up', () {
      const day = AttendanceDay(status: 'present', totalWorkHours: 10);

      final status = AttendanceHistoryCopy.status(en, day);

      expect(status.label, 'Present');
      expect(status.color, AppColors.attendancePresent);
    });

    test('hours show at most one decimal, and a whole number without one', () {
      expect(AttendanceHistoryCopy.hours(0), '0');
      expect(AttendanceHistoryCopy.hours(2), '2');
      expect(AttendanceHistoryCopy.hours(1.5), '1.5');
      expect(AttendanceHistoryCopy.hours(6.25), '6.3');
      expect(AttendanceHistoryCopy.hours(1.96), '2');
    });

    test('the OT line shows the server\'s OT hours, in each language', () {
      const day = AttendanceDay(totalWorkHours: 9.5, overtimeHours: 1.5);

      expect(AttendanceHistoryCopy.overtimeLine(en, day), 'OT 1.5 h');
      expect(AttendanceHistoryCopy.overtimeLine(lo, day), 'ໂອທີ 1.5 ຊົ່ວໂມງ');
    });

    test('no OT line without approved OT, however long the day was', () {
      expect(
        AttendanceHistoryCopy.overtimeLine(
          en,
          const AttendanceDay(status: 'present', totalWorkHours: 10),
        ),
        isNull,
      );
      // Too little to show as a number: no "OT 0 h" line either.
      expect(
        AttendanceHistoryCopy.overtimeLine(
          en,
          const AttendanceDay(totalWorkHours: 10, overtimeHours: 0.04),
        ),
        isNull,
      );
      expect(
        AttendanceHistoryCopy.overtimeLine(
          en,
          const AttendanceDay(totalWorkHours: 10, overtimeHours: -1),
        ),
        isNull,
      );
    });

    test('a plain day with no flags reads as present', () {
      const day = AttendanceDay(totalWorkHours: 8);

      expect(AttendanceHistoryCopy.status(en, day).label, 'Present');
    });
  });

  group('AttendanceHistoryNotifier', () {
    late FakeAttendanceRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAttendanceRepository();
      container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() => container.dispose());

    Future<AttendanceHistoryNotifier> ready() async {
      // The provider is `autoDispose`; a bare `container.read` leaves it with
      // no listener, so Riverpod tears it down again before the test can act
      // on it. A no-op listen, same as a widget's `ref.watch`, keeps it alive
      // — done here rather than in `setUp` so it still builds after each
      // test has finished configuring the fake repository's response.
      container.listen(attendanceHistoryNotifierProvider, (_, _) {});
      final notifier = container.read(
        attendanceHistoryNotifierProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    test('loads the current month on creation', () async {
      final now = DateTime.now();
      repository.monthSummary = const Result.success(
        AttendanceSummary(presentDays: 15),
      );

      await ready();

      final state = container.read(attendanceHistoryNotifierProvider);
      expect(state.month, DateTime(now.year, now.month));
      expect(state.summary.value?.presentDays, 15);
      expect(repository.recordsRanges, hasLength(1));
      expect(repository.recordsRanges.single, DateRange.month(now));
    });

    test('previousMonth steps back and reloads', () async {
      final notifier = await ready();
      final before = container.read(attendanceHistoryNotifierProvider).month;

      notifier.previousMonth();
      await Future<void>.delayed(Duration.zero);

      final month = container.read(attendanceHistoryNotifierProvider).month;
      expect(month, DateTime(before.year, before.month - 1));
      expect(repository.recordsRanges, hasLength(2));
    });

    test('nextMonth is a no-op once the current month is showing', () async {
      final notifier = await ready();

      notifier.nextMonth();
      await Future<void>.delayed(Duration.zero);

      // Still just the one load from build().
      expect(repository.recordsRanges, hasLength(1));
      expect(
        container.read(attendanceHistoryNotifierProvider).canGoNext,
        isFalse,
      );
    });

    test('toggleExpanded flips one row without touching the rest', () async {
      final notifier = await ready();

      notifier.toggleExpanded(0);
      expect(
        container.read(attendanceHistoryNotifierProvider).expandedIndexes,
        {0},
      );

      notifier.toggleExpanded(1);
      notifier.toggleExpanded(0);
      expect(
        container.read(attendanceHistoryNotifierProvider).expandedIndexes,
        {1},
      );
    });

    test('changing month clears which rows were expanded', () async {
      final notifier = await ready();
      notifier.toggleExpanded(0);

      notifier.previousMonth();
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(attendanceHistoryNotifierProvider).expandedIndexes,
        isEmpty,
      );
    });

    test('retry re-runs the fetch for the month currently shown', () async {
      final notifier = await ready();
      expect(repository.recordsRanges, hasLength(1));

      notifier.retry();
      await Future<void>.delayed(Duration.zero);

      expect(repository.recordsRanges, hasLength(2));
      expect(repository.recordsRanges[0], repository.recordsRanges[1]);
    });

    test('a records failure surfaces as an error state', () async {
      repository.monthRecords = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await ready();

      expect(
        container.read(attendanceHistoryNotifierProvider).records.hasError,
        isTrue,
      );
    });
  });

  group('AttendanceHistoryState.showsSummary', () {
    const notLinked = Failure.validation(
      message: 'employee not found',
      code: 'EMPLOYEE_NOT_FOUND',
    );
    const offline = Failure.network(message: 'offline');
    final month = DateTime(2026, 6);

    AsyncValue<T> failed<T>(Failure failure) =>
        AsyncValue<T>.error(failure, StackTrace.empty);

    AttendanceHistoryState state({
      required AsyncValue<List<AttendanceDay>> records,
      required AsyncValue<AttendanceSummary> summary,
    }) => AttendanceHistoryState(
      month: month,
      records: records,
      summary: summary,
    );

    test('shown in every ordinary state', () {
      const loaded = AsyncValue<AttendanceSummary>.data(AttendanceSummary.empty);
      const rows = AsyncValue<List<AttendanceDay>>.data([]);

      expect(
        AttendanceHistoryState(month: month).showsSummary,
        isTrue,
        reason: 'both loading',
      );
      expect(state(records: rows, summary: loaded).showsSummary, isTrue);
      expect(
        state(records: rows, summary: failed(offline)).showsSummary,
        isTrue,
      );
      expect(
        state(records: failed(offline), summary: failed(offline)).showsSummary,
        isTrue,
      );
    });

    test('hidden when both say "not linked": the list says it once', () {
      expect(
        state(
          records: failed(notLinked),
          summary: failed(notLinked),
        ).showsSummary,
        isFalse,
      );
    });

    test('hidden while the summary is still on its way to the same answer', () {
      expect(
        state(
          records: failed(notLinked),
          summary: const AsyncValue.loading(),
        ).showsSummary,
        isFalse,
      );
    });

    test('shown when only the summary is not linked, or when it failed '
        'another way', () {
      expect(
        state(
          records: const AsyncValue.data([]),
          summary: failed(notLinked),
        ).showsSummary,
        isTrue,
      );
      expect(
        state(
          records: failed(notLinked),
          summary: failed(offline),
        ).showsSummary,
        isTrue,
      );
    });
  });

  group('AttendanceHistoryPage', () {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);
    // The 21st/22nd exist in every month, so the fixture never has to dodge
    // a short February.
    final day22 = DateTime(now.year, now.month, 22);
    final day21 = DateTime(now.year, now.month, 21);

    late FakeAttendanceRepository repository;

    setUp(() {
      repository = FakeAttendanceRepository()
        ..monthSummary = const Result.success(
          AttendanceSummary(
            totalWorkingDays: 23,
            presentDays: 15,
            lateDays: 2,
            halfDays: 1,
            incompleteDays: 3,
            absentDays: 4,
            leaveDays: 5,
            totalWorkHours: 121.5,
            totalOvertimeHours: 6.5,
          ),
        )
        ..monthRecords = Result.success([
          AttendanceDay(
            date: day22,
            totalWorkHours: 9.5,
            overtimeHours: 1.5,
            sessions: [
              AttendanceSession(
                partName: 'Morning',
                partNameLo: 'ກະເຊົ້າ',
                clockIn: DateTime(day22.year, day22.month, day22.day, 8, 2),
                clockOut: DateTime(day22.year, day22.month, day22.day, 12, 1),
                method: 'gps',
                locationLabel: 'Office Center',
              ),
              AttendanceSession(
                partName: 'Afternoon',
                partNameLo: 'ກະແລງ',
                clockIn: DateTime(day22.year, day22.month, day22.day, 12, 58),
                clockOut: DateTime(day22.year, day22.month, day22.day, 17, 5),
                method: 'gps',
                locationLabel: 'Office Center',
              ),
            ],
          ),
          AttendanceDay(
            date: day21,
            totalWorkHours: 7.6,
            sessions: [
              AttendanceSession(
                clockIn: DateTime(day21.year, day21.month, day21.day, 8, 26),
                clockOut: DateTime(day21.year, day21.month, day21.day, 17, 2),
                isLate: true,
                lateMinutes: 11,
              ),
            ],
          ),
        ]);
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const AttendanceHistoryPage(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('renders the month, the stat cards and the daily rows', (
      tester,
    ) async {
      final en = lookupAppLocalizations(const Locale('en'));

      await pumpPage(tester);

      expect(
        find.text(AttendanceHistoryCopy.monthYear(en, thisMonth)),
        findsOneWidget,
      );
      expect(find.text('15'), findsOneWidget);
      expect(find.text('121.5 h'), findsOneWidget);
      expect(find.text('Late by 11 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the six day counts, the base line and the hours', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Out of 23 working days'), findsOneWidget);
      for (final (label, value) in const [
        ('Days present', '15'),
        ('Days late', '2'),
        ('Half day', '1'),
        ('Incomplete', '3'),
        ('Days absent', '4'),
        ('Leave Days', '5'),
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
        expect(find.text(value), findsOneWidget, reason: '$label = $value');
      }
      expect(find.text('Work Hours'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the summary shows the month\'s OT hours as the server sent '
        'them', (tester) async {
      await pumpPage(tester);

      expect(find.text('OT Hours'), findsOneWidget);
      expect(find.text('6.5 h'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a month with no OT shows 0, not an empty card', (
      tester,
    ) async {
      repository.monthSummary = const Result.success(
        AttendanceSummary(totalWorkingDays: 23, totalWorkHours: 121.5),
      );

      await pumpPage(tester);

      expect(find.text('OT Hours'), findsOneWidget);
      expect(find.text('0 h'), findsOneWidget);
    });

    testWidgets('only the day with approved OT shows an OT line', (
      tester,
    ) async {
      await pumpPage(tester);

      // The 22nd has 1.5 h of approved OT; the 21st has none.
      expect(find.text('OT 1.5 h'), findsOneWidget);
      expect(find.textContaining('OT '), findsNWidgets(2)); // + "OT Hours"
      expect(tester.takeException(), isNull);
    });

    group('a login with no employee record', () {
      const notLinked = Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      );
      const text =
          'Your account is not linked to an employee record. '
          'Please contact HR.';

      testWidgets('says so once, with no Retry, when both loads fail', (
        tester,
      ) async {
        repository
          ..monthSummary = const Result.failure(notLinked)
          ..monthRecords = const Result.failure(notLinked);

        await pumpPage(tester);

        expect(find.text(text), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        expect(find.text('Could not load attendance.'), findsNothing);
      });

      testWidgets('says so in the summary strip when only the summary fails', (
        tester,
      ) async {
        repository.monthSummary = const Result.failure(notLinked);

        await pumpPage(tester);

        expect(find.text(text), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        // The list still loaded.
        expect(find.text('Late by 11 min'), findsOneWidget);
      });
    });

    testWidgets('a not-linked list with a summary that failed another way '
        'keeps both messages: they are different facts', (tester) async {
      repository
        ..monthSummary = const Result.failure(
          Failure.network(message: 'offline'),
        )
        ..monthRecords = const Result.failure(
          Failure.validation(
            message: 'employee not found',
            code: 'EMPLOYEE_NOT_FOUND',
          ),
        );

      await pumpPage(tester);

      expect(find.text('Could not load attendance.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.text(
          'Your account is not linked to an employee record. '
          'Please contact HR.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('another failure says "could not load attendance" with a '
        'Retry, on the strip and on the list', (tester) async {
      repository
        ..monthSummary = const Result.failure(
          Failure.network(message: 'offline'),
        )
        ..monthRecords = const Result.failure(
          Failure.server(message: 'boom', statusCode: 500),
        );

      await pumpPage(tester);

      expect(find.text('Could not load attendance.'), findsNWidgets(2));
      expect(find.text('Retry'), findsNWidgets(2));
      // Never zeros standing in for numbers that did not load.
      expect(find.text('Days present'), findsNothing);
    });

    testWidgets('expanding a row reveals its sessions', (tester) async {
      final en = lookupAppLocalizations(const Locale('en'));

      await pumpPage(tester);

      expect(find.text('Office Center'), findsNothing);

      await tester.tap(find.text(AttendanceHistoryCopy.dayTitle(en, day22)));
      await tester.pump();

      expect(find.text('GPS · Office Center'), findsNWidgets(2));
      // Each row is named after its shift part, in the App's language. That
      // is `localeProvider`'s, which defaults to Lao, so the Lao names show.
      expect(find.text('ກະເຊົ້າ'), findsOneWidget);
      expect(find.text('ກະແລງ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    group('"forgot to scan" from a day (#44)', () {
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      Future<List<String>> pumpWithRouter(WidgetTester tester) async {
        final opened = <String>[];
        repository.monthRecords = Result.success([
          AttendanceDay(
            date: today,
            sessions: [
              AttendanceSession(
                partId: 'sd-am',
                partName: 'Morning',
                partStartTime: '08:00:00',
                partEndTime: '12:00:00',
                clockIn: DateTime(today.year, today.month, today.day, 8, 2),
              ),
            ],
          ),
          if (tomorrow.month == today.month)
            AttendanceDay(date: tomorrow, sessions: const []),
        ]);
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const AttendanceHistoryPage(),
            ),
            GoRoute(
              path: AppRoutes.timeCorrectionRequest,
              builder: (_, state) {
                opened.add(state.uri.toString());
                return const Scaffold(body: Text('FORM'));
              },
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(repository),
            ],
            child: DefaultAssetBundle(
              bundle: TestAssetBundle(),
              child: MaterialApp.router(
                routerConfig: router,
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        return opened;
      }

      testWidgets('under a session: opens the form with that day and part',
          (tester) async {
        final en = lookupAppLocalizations(const Locale('en'));
        final opened = await pumpWithRouter(tester);

        await tester.tap(find.text(AttendanceHistoryCopy.dayTitle(en, today)));
        await tester.pump();
        // The button sits under the summary's rows: bring it on screen.
        await tester.ensureVisible(find.text(en.forgotClockInMenu));
        await tester.pump();
        await tester.tap(find.text(en.forgotClockInMenu));
        await tester.pumpAndSettle();

        expect(
          opened.single,
          AppRoutes.timeCorrectionRequestFor(today, partId: 'sd-am'),
        );
      });

      testWidgets('no button on a day after today', (tester) async {
        if (tomorrow.month != today.month) return;
        final en = lookupAppLocalizations(const Locale('en'));
        await pumpWithRouter(tester);

        await tester.tap(
          find.text(AttendanceHistoryCopy.dayTitle(en, tomorrow)),
        );
        await tester.pump();

        expect(find.text(en.forgotClockInMenu), findsNothing);
      });
    });

    testWidgets('a session with no shift part is named by its position', (
      tester,
    ) async {
      final en = lookupAppLocalizations(const Locale('en'));

      await pumpPage(tester);
      // The second day sits under the summary's rows: bring it on screen.
      await tester.ensureVisible(
        find.text(AttendanceHistoryCopy.dayTitle(en, day21)),
      );
      await tester.pump();
      await tester.tap(find.text(AttendanceHistoryCopy.dayTitle(en, day21)));
      await tester.pump();

      expect(find.text(en.shiftMorningLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the month switcher steps back a month', (tester) async {
      final en = lookupAppLocalizations(const Locale('en'));

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text(AttendanceHistoryCopy.monthYear(en, previousMonth)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
