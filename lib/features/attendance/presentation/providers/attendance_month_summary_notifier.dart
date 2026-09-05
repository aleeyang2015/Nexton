import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance_providers.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/date_range.dart';

/// This month's present/late/absent/hours roll-up — the numbers the home
/// screen's attendance history card shows above the "view all" link into
/// [AttendanceHistoryPage].
///
/// Kept separate from [AttendanceHistoryNotifier]: that one also loads the
/// full daily record list and tracks which rows are expanded, both of which
/// the home card has no use for and shouldn't pay the network cost of.
///
/// Unlike [AttendanceHistoryNotifier] — which surfaces a failed load with a
/// retry, because the history page *is* the attendance record and a wrong
/// "0" there would read as "you were absent all month" — this is a small
/// at-a-glance card with a "view all" straight into that same page. A slow
/// or failing summary here degrades to zeros instead of parking the home
/// screen behind a spinner or an error row.
class AttendanceMonthSummaryNotifier
    extends AutoDisposeAsyncNotifier<AttendanceSummary> {
  /// Bounds the wait below Dio's own `receiveTimeout` (§core/constants):
  /// this endpoint has been observed to hang past that with no response and
  /// no `DioException` ever thrown, so this is a second, independent backstop
  /// rather than a tighter duplicate of the same guarantee.
  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<AttendanceSummary> build() => _load();

  /// Re-runs the fetch, e.g. after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<AttendanceSummary> _load() async {
    final range = DateRange.month(DateTime.now());

    try {
      final result = await ref
          .read(getMonthlySummaryUseCaseProvider)(range)
          .timeout(_timeout);

      return result.fold((failure) {
        _logFallback(range, failure.message);
        return AttendanceSummary.empty;
      }, (summary) => summary);
    } on TimeoutException {
      _logFallback(range, 'no response after $_timeout');
      return AttendanceSummary.empty;
    }
  }

  void _logFallback(DateRange range, String reason) {
    debugPrint(
      '[AttendanceMonthSummary] GET records/summary/my '
      '(${_isoDate(range.start)}..${_isoDate(range.end)}) $reason — '
      'showing 0s on the home card instead.',
    );
  }

  static String _isoDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final attendanceMonthSummaryNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      AttendanceMonthSummaryNotifier,
      AttendanceSummary
    >(AttendanceMonthSummaryNotifier.new);
