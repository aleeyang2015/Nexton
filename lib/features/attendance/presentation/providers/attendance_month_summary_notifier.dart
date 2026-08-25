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
class AttendanceMonthSummaryNotifier extends AsyncNotifier<AttendanceSummary> {
  @override
  Future<AttendanceSummary> build() => _load();

  /// Re-runs the fetch, e.g. after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<AttendanceSummary> _load() async {
    final range = DateRange.month(DateTime.now());
    final result = await ref.read(getMonthlySummaryUseCaseProvider)(range);
    return result.fold((failure) => throw failure, (summary) => summary);
  }
}

final attendanceMonthSummaryNotifierProvider =
    AsyncNotifierProvider<AttendanceMonthSummaryNotifier, AttendanceSummary>(
      AttendanceMonthSummaryNotifier.new,
    );
