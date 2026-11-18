import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';

part 'time_correction_history_state.freezed.dart';

/// What "My requests"' "forgot to scan" tab renders from (#45): the
/// requests of the picked status, a page at a time. [filter] is null for
/// "all".
///
/// The status is a server filter (`?status=`), so each pick loads its own
/// list from its first page; there are no per-status counts to show.
@freezed
class TimeCorrectionHistoryState with _$TimeCorrectionHistoryState {
  const TimeCorrectionHistoryState._();

  const factory TimeCorrectionHistoryState({
    @Default(AsyncValue<PagedList<TimeCorrectionRecord>>.loading())
    AsyncValue<PagedList<TimeCorrectionRecord>> records,
    TimeCorrectionStatus? filter,
  }) = _TimeCorrectionHistoryState;

  /// The requests loaded so far for the picked status.
  List<TimeCorrectionRecord> get visible =>
      records.valueOrNull?.items ?? const [];
}
