import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
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
/// A load that fails, or never answers, is an error here, never zeros. Zeros
/// are numbers: "0 present, 0 late" on the home screen reads as "you came 0
/// days", which is worse than saying the numbers could not be loaded. The
/// card shows the failure in a single line, with a Retry when one can help.
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
        _logFailure(range, failure.message);
        // Thrown, so the state is an error the card can tell apart: "not
        // linked to an employee" gets no Retry, anything else does.
        throw failure;
      }, (summary) => summary);
    } on TimeoutException {
      _logFailure(range, 'no response after $_timeout');
      throw const Failure.network(
        message: 'Request timeout. Please try again.',
        errorCode: ApiErrorCodes.timeout,
      );
    }
  }

  void _logFailure(DateRange range, String reason) {
    debugPrint(
      '[AttendanceMonthSummary] GET records/summary/my '
      '(month=${_isoMonth(range.start)}) $reason',
    );
  }

  static String _isoMonth(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

final attendanceMonthSummaryNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      AttendanceMonthSummaryNotifier,
      AttendanceSummary
    >(AttendanceMonthSummaryNotifier.new);
