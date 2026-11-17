import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../salary_history_providers.dart';
import 'salary_history_state.dart';

/// Owns the history page's year, its payslips, the active filter, which
/// rows are expanded, and the newest payslip for the top card. The page
/// renders what comes back and forwards taps here; it holds no fetching
/// logic of its own.
///
/// The newest payslip is asked for once, when the page opens: it does not
/// depend on the year, so switching year or chip leaves it as it is. Retry
/// asks for it again with the year's list.
class SalaryHistoryNotifier extends AutoDisposeNotifier<SalaryHistoryState> {
  bool _disposed = false;

  @override
  SalaryHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final year = DateTime.now().year;
    Future.microtask(() {
      // The page may have closed before this ran.
      if (_disposed) return;
      _load(year);
      _loadLatest();
    });

    return SalaryHistoryState(year: year);
  }

  void previousYear() => _load(state.year - 1);

  void nextYear() {
    if (!state.canGoNext) return;
    _load(state.year + 1);
  }

  /// Re-runs the current year's fetch and the newest payslip's, e.g. after
  /// the user retries a failed load.
  void retry() {
    _load(state.year);
    _loadLatest();
  }

  void setFilter(SalaryHistoryFilter filter) {
    state = state.copyWith(filter: filter, expandedIndexes: {});
  }

  void toggleExpanded(int index) {
    final expanded = Set<int>.from(state.expandedIndexes);
    if (!expanded.remove(index)) expanded.add(index);
    state = state.copyWith(expandedIndexes: expanded);
  }

  /// Counts the loads, so an answer can tell it has been overtaken.
  int _loads = 0;

  Future<void> _load(int year) async {
    final loadedAs = ++_loads;
    // A fresh year resets the list and expanded rows, but keeps the chosen
    // filter — that's a display preference, not tied to any one year.
    state = SalaryHistoryState(
      year: year,
      filter: state.filter,
      latest: state.latest,
    );

    final result = await ref.read(getMyPayslipsUseCaseProvider)(year);
    // Only the latest load counts. An older one answered late, for another
    // year or for this same one (back and forward, or Retry twice), must not
    // replace the list that is showing, least of all with its failure.
    if (_disposed || loadedAs != _loads) return;
    state = state.copyWith(payslips: _toAsync(result));
  }

  /// Counts the newest-payslip loads, as [_loads] does for the year's.
  int _latestLoads = 0;

  Future<void> _loadLatest() async {
    final loadedAs = ++_latestLoads;
    // A card already showing stays while it is asked for again.
    if (!state.latest.hasValue) {
      state = state.copyWith(latest: const AsyncValue.loading());
    }

    final result = await ref.read(getMyLatestPayslipUseCaseProvider)();
    if (_disposed || loadedAs != _latestLoads) return;
    // A card that is showing is the server's own answer from moments ago: a
    // failed Retry (still offline) does not take it away.
    if (result.isFailure && state.latest.hasValue) return;
    state = state.copyWith(latest: _toAsync(result));
  }

  AsyncValue<T> _toAsync<T>(Result<T> result) => result.fold(
    (failure) => AsyncValue<T>.error(failure, StackTrace.current),
    (value) => AsyncValue<T>.data(value),
  );
}

final salaryHistoryNotifierProvider =
    NotifierProvider.autoDispose<SalaryHistoryNotifier, SalaryHistoryState>(
      SalaryHistoryNotifier.new,
    );
