import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../../time_off_providers.dart';
import 'leave_approvals_state.dart';

/// Owns the approvals tab's pending / decided lists and each decision's
/// in-flight status. The tab renders what comes back and forwards taps here;
/// it holds no fetching logic of its own.
class LeaveApprovalsNotifier extends AutoDisposeNotifier<LeaveApprovalsState> {
  bool _disposed = false;

  @override
  LeaveApprovalsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(_loadAll);
    return const LeaveApprovalsState();
  }

  /// Re-runs both fetches, e.g. after the user retries a failed load.
  void retry() => _loadAll();

  Future<void> _loadAll() async {
    state = state.copyWith(
      pending: const AsyncValue.loading(),
      history: const AsyncValue.loading(),
    );

    final pendingResult = await ref.read(getLeaveApprovalsUseCaseProvider)(
      LeaveStatus.pending,
    );
    if (_disposed) return;
    state = state.copyWith(pending: _toAsync(pendingResult));

    // History: everything the caller has already acted on. One unfiltered
    // call, kept to the decided statuses (`?status=approved`/`rejected` would
    // need two round trips).
    final historyResult = await ref.read(getLeaveApprovalsUseCaseProvider)(
      null,
    );
    if (_disposed) return;
    state = state.copyWith(
      history: _toAsync(
        historyResult.mapData(
          (list) => list
              .where(
                (r) =>
                    r.status == LeaveStatus.approved ||
                    r.status == LeaveStatus.rejected,
              )
              .toList(),
        ),
      ),
    );
  }

  Future<LeaveDecisionOutcome> approve(LeaveRequest request) {
    return _decide(
      request.id,
      () => ref.read(approveLeaveStepUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: null,
      )),
    );
  }

  Future<LeaveDecisionOutcome> reject(LeaveRequest request, String reason) {
    return _decide(
      request.id,
      () => ref.read(rejectLeaveStepUseCaseProvider)((
        id: request.id,
        reason: reason,
        stepId: request.currentStep?.id,
        note: null,
      )),
    );
  }

  Future<LeaveDecisionOutcome> _decide(
    String requestId,
    Future<Result<LeaveRequest>> Function() action,
  ) async {
    state = state.copyWith(decidingIds: {...state.decidingIds, requestId});

    final result = await action();
    if (_disposed) return const LeaveDecisionOutcome.failed();

    state = state.copyWith(
      decidingIds: {...state.decidingIds}..remove(requestId),
    );

    return result.fold(
      (failure) async {
        // The card the approver tapped is out of date. Reload first, so it
        // is gone or corrected by the time the reason is shown; otherwise
        // every retry would fail the same way.
        if (LeaveErrorCode.isStaleForApprover(failure)) {
          await _loadAll();
          return LeaveDecisionOutcome.reloaded(failure);
        }
        return LeaveDecisionOutcome.failed(failure);
      },
      (_) async {
        await _loadAll();
        return LeaveDecisionOutcome.success;
      },
    );
  }

  AsyncValue<List<LeaveRequest>> _toAsync(Result<List<LeaveRequest>> result) =>
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (data) => AsyncValue.data(data),
      );
}

final leaveApprovalsNotifierProvider =
    NotifierProvider.autoDispose<LeaveApprovalsNotifier, LeaveApprovalsState>(
      LeaveApprovalsNotifier.new,
    );
