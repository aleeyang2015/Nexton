import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
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

    test(
      'falls back to zeros instead of surfacing an error the home card '
      'would have to show a retry for',
      () async {
        final repository = FakeAttendanceRepository()
          ..monthSummary = const Result.failure(
            Failure.network(message: 'offline'),
          );
        final container = ProviderContainer(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        final summary = await container.read(
          attendanceMonthSummaryNotifierProvider.future,
        );

        expect(summary, AttendanceSummary.empty);
        expect(
          container.read(attendanceMonthSummaryNotifierProvider).hasError,
          isFalse,
        );
      },
    );

    test(
      'falls back to zeros rather than hanging forever when the backend '
      'never answers',
      () {
        fakeAsync((async) {
          final container = ProviderContainer(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(
                _HangingSummaryRepository(),
              ),
            ],
          );
          addTearDown(container.dispose);

          AttendanceSummary? result;
          unawaited(
            container
                .read(attendanceMonthSummaryNotifierProvider.future)
                .then((value) => result = value),
          );

          // Past the notifier's own timeout, well short of a real 15s wait.
          async.elapse(const Duration(seconds: 16));

          expect(result, AttendanceSummary.empty);
        });
      },
    );
  });
}
