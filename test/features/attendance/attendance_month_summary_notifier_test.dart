import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/attendance_failure_x.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_month_summary_notifier.dart';

import '../../support/attendance_test_doubles.dart';

/// A repository whose `summary()` never answers — reproducing the real
/// backend behaviour behind this notifier's fallback: the request never
/// resolves into either a response or a `DioException`.
class _HangingSummaryRepository extends FakeAttendanceRepository {
  @override
  FutureResult<AttendanceSummary> summary(DateRange range) =>
      Completer<Result<AttendanceSummary>>().future;
}

void main() {
  group('AttendanceMonthSummaryNotifier', () {
    test('loads the real summary on success', () async {
      final repository = FakeAttendanceRepository()
        ..monthSummary = const Result.success(
          AttendanceSummary(
            presentDays: 10,
            lateDays: 1,
            absentDays: 0,
            totalWorkHours: 80,
          ),
        );
      final container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final summary = await container.read(
        attendanceMonthSummaryNotifierProvider.future,
      );

      expect(summary.presentDays, 10);
      expect(summary.lateDays, 1);
    });

    test('a failure is an error, never zeros: zeros would read as "you came '
        '0 days"', () async {
      const offline = Failure.network(message: 'offline');
      final repository = FakeAttendanceRepository()
        ..monthSummary = const Result.failure(offline);
      final container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(attendanceMonthSummaryNotifierProvider, (_, _) {});

      await expectLater(
        container.read(attendanceMonthSummaryNotifierProvider.future),
        throwsA(offline),
      );

      final state = container.read(attendanceMonthSummaryNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, offline);
      expect(state.hasValue, isFalse);
    });

    test('the failure keeps its code, so "not linked to an employee" can be '
        'told apart', () async {
      const notLinked = Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      );
      final repository = FakeAttendanceRepository()
        ..monthSummary = const Result.failure(notLinked);
      final container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(attendanceMonthSummaryNotifierProvider, (_, _) {});

      await expectLater(
        container.read(attendanceMonthSummaryNotifierProvider.future),
        throwsA(notLinked),
      );
      expect(
        (container.read(attendanceMonthSummaryNotifierProvider).error!
                as Failure)
            .isEmployeeNotLinked,
        isTrue,
      );
    });

    test('a backend that never answers is a timeout error, not zeros and not '
        'a spinner forever', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(
              _HangingSummaryRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(attendanceMonthSummaryNotifierProvider, (_, _) {});

        // Past the notifier's own timeout, well short of a real 15s wait.
        async.elapse(const Duration(seconds: 16));

        final state = container.read(attendanceMonthSummaryNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.hasValue, isFalse);
        expect((state.error! as NetworkFailure).errorCode, 'TIMEOUT');
      });
    });

    test('refresh() after a failure loads the real numbers', () async {
      final repository = FakeAttendanceRepository()
        ..monthSummary = const Result.failure(
          Failure.network(message: 'offline'),
        );
      final container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(attendanceMonthSummaryNotifierProvider, (_, _) {});
      await container
          .read(attendanceMonthSummaryNotifierProvider.future)
          .then<void>((_) {}, onError: (_) {});

      repository.monthSummary = const Result.success(
        AttendanceSummary(presentDays: 12, leaveDays: 2),
      );
      await container
          .read(attendanceMonthSummaryNotifierProvider.notifier)
          .refresh();

      final state = container.read(attendanceMonthSummaryNotifierProvider);
      expect(state.hasError, isFalse);
      expect(state.requireValue.leaveDays, 2);
    });
  });
}
