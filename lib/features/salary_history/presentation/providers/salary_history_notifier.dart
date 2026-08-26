import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../salary_history_providers.dart';
import 'salary_history_state.dart';

/// Owns the history page's year, its payslips, the active filter and which
/// rows are expanded. The page renders what comes back and forwards taps
/// here; it holds no fetching logic of its own.
class SalaryHistoryNotifier extends Notifier<SalaryHistoryState> {
  bool _disposed = false;

  @override
  SalaryHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final year = DateTime.now().year;
    Future.microtask(() => _load(year));

    return SalaryHistoryState(year: year);
  }

  void previousYear() => _load(state.year - 1);

  void nextYear() {
    if (!state.canGoNext) return;
    _load(state.year + 1);
  }

  /// Re-runs the current year's fetch, e.g. after the user retries a failed
  /// load.
  void retry() => _load(state.year);

  void setFilter(SalaryHistoryFilter filter) {
    state = state.copyWith(filter: filter, expandedIndexes: {});
  }

  void toggleExpanded(int index) {
    final expanded = Set<int>.from(state.expandedIndexes);
    if (!expanded.remove(index)) expanded.add(index);
    state = state.copyWith(expandedIndexes: expanded);
  }

  Future<void> _load(int year) async {
    // A fresh year resets the list and expanded rows, but keeps the chosen
    // filter — that's a display preference, not tied to any one year.
    state = SalaryHistoryState(year: year, filter: state.filter);

    final result = await ref.read(getPayslipHistoryUseCaseProvider)(year);
    if (_disposed || state.year != year) return;
    state = state.copyWith(payslips: _toAsync(result));
  }

  AsyncValue<T> _toAsync<T>(Result<T> result) => result.fold(
    (failure) => AsyncValue<T>.error(failure, StackTrace.current),
    (value) => AsyncValue<T>.data(value),
  );
}

final salaryHistoryNotifierProvider =
    NotifierProvider<SalaryHistoryNotifier, SalaryHistoryState>(
      SalaryHistoryNotifier.new,
    );
