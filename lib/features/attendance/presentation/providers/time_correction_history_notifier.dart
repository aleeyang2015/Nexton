import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_history_state.dart';

/// The time-correction history page ("ປະຫວັດການຮ້ອງຂໍແກ້ໄຂເວລາ"): the
/// employee's requests from `GET /attendance/correction-requests/my` and the
/// picked status tab. Filtering is local — the whole list is fetched once.
class TimeCorrectionHistoryNotifier
    extends AutoDisposeNotifier<TimeCorrectionHistoryState> {
  bool _disposed = false;

  @override
  TimeCorrectionHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const TimeCorrectionHistoryState();
  }

  void selectFilter(TimeCorrectionStatus? status) =>
      state = state.copyWith(filter: status);

  /// Refetches the list — on retry, pull-to-refresh, or after a new request
  /// was filed. Records already shown stay on screen while it loads.
  Future<void> refresh() async {
    state = state.copyWith(
      records: const AsyncLoading<List<TimeCorrectionRecord>>()
          .copyWithPrevious(state.records),
    );

    final result = await ref.read(getTimeCorrectionHistoryUseCaseProvider)();
    if (_disposed) return;

    state = state.copyWith(
      records: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        AsyncValue.data,
      ),
    );
  }
}

final timeCorrectionHistoryNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionHistoryNotifier,
      TimeCorrectionHistoryState
    >(TimeCorrectionHistoryNotifier.new);
