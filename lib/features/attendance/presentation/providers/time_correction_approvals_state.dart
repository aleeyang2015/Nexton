import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';

part 'time_correction_approvals_state.freezed.dart';

/// What the "ຄຳຮ້ອງແກ້ໄຂເວລາ" approvals page renders from: every request
/// the approver can see, the status chip picked ([filter] is null for
/// "all"), the search text, and which requests have a decision in flight so
/// their buttons disable individually.
@freezed
class TimeCorrectionApprovalsState with _$TimeCorrectionApprovalsState {
  const TimeCorrectionApprovalsState._();

  const factory TimeCorrectionApprovalsState({
    @Default(AsyncValue<List<TimeCorrectionDetail>>.loading())
    AsyncValue<List<TimeCorrectionDetail>> requests,
    TimeCorrectionStatus? filter,
    @Default('') String query,
    @Default(<String>{}) Set<String> decidingIds,
  }) = _TimeCorrectionApprovalsState;

  List<TimeCorrectionDetail> get _loaded => requests.valueOrNull ?? const [];

  /// The requests matching the picked chip and the search text. The search
  /// is a case-insensitive match on the employee's name or number.
  List<TimeCorrectionDetail> get visible {
    final needle = query.trim().toLowerCase();
    return _loaded
        .where((r) => filter == null || r.status == filter)
        .where((r) => needle.isEmpty || _matches(r, needle))
        .toList();
  }

  /// How many requests have [status]; every request when it is null. Zero
  /// until the list has loaded.
  int countOf(TimeCorrectionStatus? status) => status == null
      ? _loaded.length
      : _loaded.where((r) => r.status == status).length;

  static bool _matches(TimeCorrectionDetail request, String needle) {
    final employee = request.employee;
    return employee.name.toLowerCase().contains(needle) ||
        (employee.employeeNumber?.toLowerCase().contains(needle) ?? false);
  }
}
