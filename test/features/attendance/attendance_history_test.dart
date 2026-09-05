import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_history_notifier.dart';
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
                  'method': 'gps',
                  'location_name': 'Office Center',
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
      expect(adapter.lastRequest!.queryParameters['start_date'], '2026-06-01');
      expect(adapter.lastRequest!.queryParameters['end_date'], '2026-06-30');
      // ASCII digits regardless of the active locale.
      expect(
        adapter.lastRequest!.queryParameters['start_date'],
        matches(r'^\d{4}-\d{2}-\d{2}$'),
      );

      expect(days, hasLength(2));
      expect(days.first.date, DateTime(2026, 6, 22)); // newest first

      final late = days.last;
      expect(late.isLate, isTrue);
      expect(late.lateMinutes, 11);
      expect(late.sessions.single.method, 'gps');
      expect(late.sessions.single.locationLabel, 'Office Center');

      final earlyExit = days.first;
      expect(earlyExit.isEarlyExit, isTrue);
      expect(earlyExit.earlyExitMinutes, 20);
    });

    test('summary() reads the roll-up fields', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'present_days': 15,
            'late_days': 2,
            'absent_days': 0,
            'total_work_hours': 121.5,
          },
        };

      final summary = await source.summary(range);

      expect(adapter.lastRequest!.path, contains('/attendance/records/summary/my'));
      expect(summary.presentDays, 15);
      expect(summary.lateDays, 2);
      expect(summary.totalWorkHours, 121.5);
    });
  });

  group('AttendanceHistoryCopy', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final lo = lookupAppLocalizations(const Locale('lo'));

    test('monthYear names the month in each language', () {
      expect(AttendanceHistoryCopy.monthYear(en, DateTime(2026, 6)), 'June 2026');
      expect(AttendanceHistoryCopy.monthYear(lo, DateTime(2026, 6)), 'ມິຖຸນາ 2026');
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

    test('an early exit outranks a late arrival and overtime', () {
      final day = AttendanceDay(
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

      expect(status.label, 'Left 20 min early');
    });

    test('a late day without a minute count still names the status', () {
      final day = AttendanceDay(
        sessions: const [AttendanceSession(isLate: true)],
      );

      expect(AttendanceHistoryCopy.status(en, day).label, 'Late');
    });

    test('work beyond 8 hours reads as overtime when otherwise on time', () {
      final day = AttendanceDay(totalWorkHours: 9.5);

      expect(AttendanceHistoryCopy.status(en, day).label, 'OT 1.5h');
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
      final notifier = container.read(attendanceHistoryNotifierProvider.notifier);
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
      expect(container.read(attendanceHistoryNotifierProvider).canGoNext, isFalse);
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
          AttendanceSummary(presentDays: 15, lateDays: 2, totalWorkHours: 121.5),
        )
        ..monthRecords = Result.success([
          AttendanceDay(
            date: day22,
            totalWorkHours: 8,
            sessions: [
              AttendanceSession(
                label: '08:00–12:00',
                clockIn: DateTime(day22.year, day22.month, day22.day, 8, 2),
                clockOut: DateTime(day22.year, day22.month, day22.day, 12, 1),
                method: 'gps',
                locationLabel: 'Office Center',
              ),
              AttendanceSession(
                label: '13:00–17:00',
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
          overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
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
      expect(find.text('121.5'), findsOneWidget);
      expect(find.text('Late by 11 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanding a row reveals its sessions', (tester) async {
      final en = lookupAppLocalizations(const Locale('en'));

      await pumpPage(tester);

      expect(find.text('Office Center'), findsNothing);

      await tester.tap(find.text(AttendanceHistoryCopy.dayTitle(en, day22)));
      await tester.pump();

      expect(find.text('GPS · Office Center'), findsNWidgets(2));
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
