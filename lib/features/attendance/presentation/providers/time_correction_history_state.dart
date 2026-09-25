import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';

part 'time_correction_history_state.freezed.dart';

/// The filed time-correction requests and the status tab picked on the
/// history page. [filter] is null for the "all" tab.
@freezed
class TimeCorrectionHistoryState with _$TimeCorrectionHistoryState {
  const TimeCorrectionHistoryState._();

  const factory TimeCorrectionHistoryState({
    @Default(AsyncValue<List<TimeCorrectionRecord>>.loading())
    AsyncValue<List<TimeCorrectionRecord>> records,
    TimeCorrectionStatus? filter,
  }) = _TimeCorrectionHistoryState;

  List<TimeCorrectionRecord> get _loaded => records.valueOrNull ?? const [];

  /// The records the picked tab shows.
  List<TimeCorrectionRecord> get visible => filter == null
      ? _loaded
      : _loaded.where((r) => r.status == filter).toList();

  /// How many records have [status]; every record when it is null. Zero
  /// until the list has loaded.
  int countOf(TimeCorrectionStatus? status) => status == null
      ? _loaded.length
      : _loaded.where((r) => r.status == status).length;
}
