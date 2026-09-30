import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../time_off/data/datasources/leave_error_code.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_approvals_state.dart';

/// The approvals page ("ຄຳຮ້ອງແກ້ໄຂເວລາ"): the requests from
/// `GET /attendance/correction-requests/my-approvals`, one list per status
/// the dropdown offers, narrowed locally by the search box, and each
/// decision's in-flight status — the same shape as [LeaveApprovalsNotifier].
///
/// The status buckets are fetched together rather than on demand, because
/// the dropdown shows each one's count next to its label.
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
    return const TimeCorrectionApprovalsState();
  }

  /// The dropdown is typed for a nullable status ("all" on the employee's
  /// own history page); this page never offers it.
  void selectFilter(TimeCorrectionStatus? status) {
    if (status == null) return;
    state = state.copyWith(filter: status);
  }

  void search(String query) => state = state.copyWith(query: query);

  /// Refetches every status bucket — on retry, pull-to-refresh, or after a
  /// decision. Requests already shown stay on screen while it loads.
  Future<void> refresh() async {
    state = state.copyWith(
      requests:
          const AsyncLoading<
                Map<TimeCorrectionStatus, List<TimeCorrectionDetail>>
              >()
              .copyWithPrevious(state.requests),
    );

    final useCase = ref.read(getTimeCorrectionApprovalsUseCaseProvider);
    final results = await Future.wait(
      TimeCorrectionApprovalsState.statuses.map(useCase.call),
    );
    if (_disposed) return;

    // One bucket failing leaves the page with a half-truth — a "0" count on
    // a status that may well have requests — so the whole load fails.
    final failure = results
        .map((result) => result.failureOrNull)
        .nonNulls
        .firstOrNull;
    if (failure != null) {
      state = state.copyWith(
        requests: AsyncValue.error(failure, StackTrace.current),
      );
      return;
    }

    state = state.copyWith(
      requests: AsyncValue.data({
        for (final (index, status)
            in TimeCorrectionApprovalsState.statuses.indexed)
          status: results[index].getOrElse(const []),
      }),
    );
  }

  /// Approves [request]. Resolves to null when it went through, else the
  /// failure for the page to report.
  Future<Failure?> approve(TimeCorrectionDetail request) => _decide(
    request.id,
    () => ref.read(approveTimeCorrectionUseCaseProvider)((
      id: request.id,
      stepId: request.currentStep?.id,
    )),
  );

  /// Rejects [request] with [note], the reason the employee is shown. Same
  /// contract as [approve].
  Future<Failure?> reject(TimeCorrectionDetail request, String note) => _decide(
    request.id,
    () => ref.read(rejectTimeCorrectionUseCaseProvider)((
      id: request.id,
      note: note,
      stepId: request.currentStep?.id,
    )),
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
    // A decision moves the request on, and so does someone else's decision
    // on a step this one aimed at (`STEP_CHANGED`, §4.7) — either way the
    // lists are refetched, so the card shows where the request now stands.
    if (failure == null || _isStepChanged(failure)) await refresh();
    return failure;
  }

  bool _isStepChanged(Failure failure) => failure.maybeWhen(
    validation: (message, _) => message == LeaveErrorCode.tokenStepChanged,
    orElse: () => false,
  );
}

final timeCorrectionApprovalsNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionApprovalsNotifier,
      TimeCorrectionApprovalsState
    >(TimeCorrectionApprovalsNotifier.new);
