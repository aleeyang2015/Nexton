import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_approvals_state.dart';

/// The approvals page ("ຄຳຮ້ອງແກ້ໄຂເວລາ"): the requests from
/// `GET /attendance/correction-requests/my-approvals`, filtered locally by
/// status chip and search text, and each decision's in-flight status — the
/// same shape as [LeaveApprovalsNotifier]. The whole list is fetched once.
class TimeCorrectionApprovalsNotifier
    extends AutoDisposeNotifier<TimeCorrectionApprovalsState> {
  bool _disposed = false;

  @override
  TimeCorrectionApprovalsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    // The dropdown has no "all" option, so the page opens on the status an
    // approver comes for.
    return const TimeCorrectionApprovalsState(
      filter: TimeCorrectionStatus.pending,
    );
  }

  void selectFilter(TimeCorrectionStatus? status) =>
      state = state.copyWith(filter: status);

  void search(String query) => state = state.copyWith(query: query);

  /// Refetches the list — on retry, pull-to-refresh, or after a decision.
  /// Requests already shown stay on screen while it loads.
  Future<void> refresh() async {
    state = state.copyWith(
      requests: const AsyncLoading<List<TimeCorrectionDetail>>()
          .copyWithPrevious(state.requests),
    );

    final result = await ref.read(getTimeCorrectionApprovalsUseCaseProvider)();
    if (_disposed) return;

    state = state.copyWith(
      requests: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        AsyncValue.data,
      ),
    );
  }

  /// Approves [id]. Resolves to null when it went through, else the failure
  /// for the page to report.
  Future<Failure?> approve(String id) =>
      _decide(id, () => ref.read(approveTimeCorrectionUseCaseProvider)(id));

  /// Rejects [id] with [reason]. Same contract as [approve].
  Future<Failure?> reject(String id, String reason) => _decide(
    id,
    () =>
        ref.read(rejectTimeCorrectionUseCaseProvider)((id: id, reason: reason)),
  );

  Future<Failure?> _decide(
    String id,
    Future<Result<Unit>> Function() action,
  ) async {
    if (state.decidingIds.contains(id)) return null;
    state = state.copyWith(decidingIds: {...state.decidingIds, id});

    final result = await action();
    if (_disposed) return result.failureOrNull;

    state = state.copyWith(decidingIds: {...state.decidingIds}..remove(id));

    final failure = result.failureOrNull;
    // A decision moves the request on; the list is refetched so the card
    // shows its new status (and leaves the "pending" chip).
    if (failure == null) await refresh();
    return failure;
  }
}

final timeCorrectionApprovalsNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionApprovalsNotifier,
      TimeCorrectionApprovalsState
    >(TimeCorrectionApprovalsNotifier.new);
