import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'offsite_history_state.dart';

/// The off-site history page: the employee's own requests from
/// `GET /attendance/offsite-requests/my`, the picked status tab, and the
/// withdrawal of a request still pending. Filtering is local — the whole list
/// is fetched once, as on the time-correction history page.
class OffsiteHistoryNotifier extends AutoDisposeNotifier<OffsiteHistoryState> {
  bool _disposed = false;

  @override
  OffsiteHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const OffsiteHistoryState();
  }

  void selectFilter(TimeCorrectionStatus? status) =>
      state = state.copyWith(filter: status);

  /// Refetches the list — on retry, pull-to-refresh, or after the form closes.
  /// Requests already shown stay on screen while it loads.
  Future<void> refresh() async {
    state = state.copyWith(
      requests: const AsyncLoading<List<OffsiteRequestDetail>>()
          .copyWithPrevious(state.requests),
    );

    final result = await ref.read(getOffsiteHistoryUseCaseProvider)();
    if (_disposed) return;

    state = state.copyWith(
      requests: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        AsyncValue.data,
      ),
    );
  }

  /// Withdraws [request] (§9). Resolves to null when it went through, else the
  /// failure for the page to report.
  ///
  /// The list is refetched either way: on success to show the request as
  /// cancelled, and on `CANNOT_CANCEL` because that answer means the card was
  /// stale — the request was approved or already withdrawn since it loaded, and
  /// the employee should see where it actually stands.
  Future<Failure?> cancel(OffsiteRequestDetail request) async {
    final id = request.id;
    if (state.cancellingIds.contains(id)) return null;
    state = state.copyWith(cancellingIds: {...state.cancellingIds, id});

    final result = await ref.read(cancelOffsiteRequestUseCaseProvider)(id);
    if (_disposed) return result.failureOrNull;

    state = state.copyWith(cancellingIds: {...state.cancellingIds}..remove(id));
    await refresh();
    return result.failureOrNull;
  }
}

final offsiteHistoryNotifierProvider =
    NotifierProvider.autoDispose<OffsiteHistoryNotifier, OffsiteHistoryState>(
      OffsiteHistoryNotifier.new,
    );
