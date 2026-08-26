import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/payslip.dart';

part 'salary_history_state.freezed.dart';

/// Which payslips the list shows — mirrors the page's three filter chips.
enum SalaryHistoryFilter { all, paid, pending }

/// Everything the salary-history page renders from: the year being viewed,
/// its payslips, the active status filter, and which rows are expanded.
@freezed
class SalaryHistoryState with _$SalaryHistoryState {
  const SalaryHistoryState._();

  const factory SalaryHistoryState({
    required int year,
    @Default(SalaryHistoryFilter.all) SalaryHistoryFilter filter,
    @Default(AsyncValue<List<Payslip>>.loading())
    AsyncValue<List<Payslip>> payslips,
    @Default(<int>{}) Set<int> expandedIndexes,
  }) = _SalaryHistoryState;

  /// A year later than this one is in the future — nothing to show yet.
  bool get canGoNext => year < DateTime.now().year;

  /// The full year's payslips, unaffected by [filter] — the latest one backs
  /// the page's highlighted summary card regardless of which chip is active.
  List<Payslip> get all => payslips.valueOrNull ?? const [];

  /// [all], narrowed to the active filter — what the list below the summary
  /// card renders.
  List<Payslip> get filtered => switch (filter) {
    SalaryHistoryFilter.all => all,
    SalaryHistoryFilter.paid =>
      all.where((p) => p.status == PayslipStatus.paid).toList(),
    SalaryHistoryFilter.pending =>
      all.where((p) => p.status == PayslipStatus.pending).toList(),
  };
}
