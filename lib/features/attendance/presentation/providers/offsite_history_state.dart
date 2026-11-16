import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';

part 'offsite_history_state.freezed.dart';

/// What the off-site history page renders from: the requests the employee has
/// filed, the status tab picked, and which of them have a withdrawal in flight
/// so their buttons disable individually. [filter] is null for the "all" tab.
///
/// One list, filtered locally — the same shape as
/// [TimeCorrectionHistoryState], and for the same reason: `GET …/my` answers
/// with each request's own status, so the buckets and their counts can be read
/// off a single fetch. The approvals tab has to keep its buckets apart because
/// `my-approvals` answers a status against the *caller's step*; here there is
/// no such distinction.
@freezed
class OffsiteHistoryState with _$OffsiteHistoryState {
  const OffsiteHistoryState._();

  const factory OffsiteHistoryState({
    @Default(AsyncValue<List<OffsiteRequestDetail>>.loading())
    AsyncValue<List<OffsiteRequestDetail>> requests,
    TimeCorrectionStatus? filter,
    @Default(<String>{}) Set<String> cancellingIds,
  }) = _OffsiteHistoryState;

  List<OffsiteRequestDetail> get _loaded => requests.valueOrNull ?? const [];

  /// The requests the picked tab shows.
  List<OffsiteRequestDetail> get visible => filter == null
      ? _loaded
      : _loaded.where((r) => r.status == filter).toList();

  /// How many requests have [status]; every one of them when it is null. Zero
  /// until the list has loaded.
  int countOf(TimeCorrectionStatus? status) => status == null
      ? _loaded.length
      : _loaded.where((r) => r.status == status).length;
}
