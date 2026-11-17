import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/payslip_record.dart';

part 'salary_history_state.freezed.dart';

/// Which payslips the list shows — the page's two filter chips. There is no
/// "pending": staff are only given payslips HR has approved or paid.
enum SalaryHistoryFilter { all, paid }

/// Everything the salary-history page renders from: the year being viewed,
/// its payslips as the server sent them, the active status filter, which
/// rows are expanded, and the newest payslip for the top card.
@freezed
class SalaryHistoryState with _$SalaryHistoryState {
  const SalaryHistoryState._();

  const factory SalaryHistoryState({
    required int year,
    @Default(SalaryHistoryFilter.all) SalaryHistoryFilter filter,
    @Default(AsyncValue<List<PayslipRecord>>.loading())
    AsyncValue<List<PayslipRecord>> payslips,
    @Default(<int>{}) Set<int> expandedIndexes,

    /// The newest payslip, whatever year is showing (`/my/latest`): the top
    /// card. Null when there is none.
    @Default(AsyncValue<PayslipLatest?>.loading())
    AsyncValue<PayslipLatest?> latest,
  }) = _SalaryHistoryState;

  /// A year later than this one is in the future — nothing to show yet.
  bool get canGoNext => year < DateTime.now().year;

  /// The full year's payslips in the server's order (newest pay month
  /// first), unaffected by [filter].
  List<PayslipRecord> get all => payslips.valueOrNull ?? const [];

  /// [all], narrowed to the active filter — what the list below the summary
  /// card renders. One page holds the whole year, so a chip narrows it on
  /// the phone and sends no request.
  List<PayslipRecord> get filtered => switch (filter) {
    SalaryHistoryFilter.all => all,
    SalaryHistoryFilter.paid =>
      all.where((p) => p.status == PayslipRunStatus.paid).toList(),
  };
}
