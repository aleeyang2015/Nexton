import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';

part 'time_correction_approvals_state.freezed.dart';

/// What the "ຄຳຮ້ອງແກ້ໄຂເວລາ" approvals page renders from: one list per
/// status the dropdown offers, the status picked, the search text, and
/// which requests have a decision in flight so their buttons disable
/// individually.
///
/// The lists are kept apart because `my-approvals` answers each status from
/// the caller's own step (§4.4) — `pending` is what still waits on this
/// approver, and that can't be re-derived from one unfiltered list, since a
/// request they already cleared stays `pending` overall while it sits with
/// HR.
@freezed
class TimeCorrectionApprovalsState with _$TimeCorrectionApprovalsState {
  const TimeCorrectionApprovalsState._();

  const factory TimeCorrectionApprovalsState({
    @Default(
      AsyncValue<
        Map<TimeCorrectionStatus, List<TimeCorrectionDetail>>
      >.loading(),
    )
    AsyncValue<Map<TimeCorrectionStatus, List<TimeCorrectionDetail>>> requests,
    @Default(TimeCorrectionStatus.pending) TimeCorrectionStatus filter,
    @Default('') String query,
    @Default(<String>{}) Set<String> decidingIds,
  }) = _TimeCorrectionApprovalsState;

  /// The statuses an approver filters by, in dropdown order. There is no
  /// "all" — one status is fetched at a time — and `cancelled` is the
  /// employee's own business, so neither is offered.
  static const List<TimeCorrectionStatus> statuses = [
    TimeCorrectionStatus.pending,
    TimeCorrectionStatus.approved,
    TimeCorrectionStatus.rejected,
  ];

  Map<TimeCorrectionStatus, List<TimeCorrectionDetail>> get _loaded =>
      requests.valueOrNull ?? const {};

  /// The requests of the picked status that match the search text, which is
  /// a case-insensitive match on the employee's name or number.
  List<TimeCorrectionDetail> get visible {
    final needle = query.trim().toLowerCase();
    final bucket = _loaded[filter] ?? const <TimeCorrectionDetail>[];
    if (needle.isEmpty) return bucket;
    return bucket.where((r) => _matches(r, needle)).toList();
  }

  /// How many requests [status] holds; every one of them when it is null.
  /// Zero until the lists have loaded.
  int countOf(TimeCorrectionStatus? status) => status == null
      ? _loaded.values.fold(0, (total, list) => total + list.length)
      : (_loaded[status]?.length ?? 0);

  static bool _matches(TimeCorrectionDetail request, String needle) {
    final employee = request.employee;
    return employee.name.toLowerCase().contains(needle) ||
        (employee.employeeNumber?.toLowerCase().contains(needle) ?? false);
  }
}
