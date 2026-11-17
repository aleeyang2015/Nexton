import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';

part 'offsite_history_state.freezed.dart';

/// What "My requests"' off-site tab renders from (#42): the requests of the
/// picked status, a page at a time, and which of them have a withdrawal in
/// flight so their buttons disable individually. [filter] is null for "all".
///
/// The status is a server filter (`?status=`), so each pick loads its own
/// list from its first page; there are no per-status counts to show.
@freezed
class OffsiteHistoryState with _$OffsiteHistoryState {
  const OffsiteHistoryState._();

  const factory OffsiteHistoryState({
    @Default(AsyncValue<PagedList<OffsiteRequestDetail>>.loading())
    AsyncValue<PagedList<OffsiteRequestDetail>> requests,
    TimeCorrectionStatus? filter,
    @Default(<String>{}) Set<String> cancellingIds,
  }) = _OffsiteHistoryState;

  /// The requests loaded so far for the picked status.
  List<OffsiteRequestDetail> get visible =>
      requests.valueOrNull?.items ?? const [];
}
