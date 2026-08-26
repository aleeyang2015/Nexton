import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_approval.dart';
import '../../time_off_providers.dart';
import 'leave_approvals_state.dart';

/// Owns the approvals tab's pending/history lists and each decision's
/// in-flight status. The tab renders what comes back and forwards taps
/// here; it holds no fetching logic of its own.
class LeaveApprovalsNotifier extends Notifier<LeaveApprovalsState> {
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

    final pendingResult = await ref.read(getPendingApprovalsUseCaseProvider)();
    if (_disposed) return;
    state = state.copyWith(pending: _toAsync(pendingResult));

    final historyResult = await ref.read(getApprovalHistoryUseCaseProvider)();
    if (_disposed) return;
    state = state.copyWith(history: _toAsync(historyResult));
  }

  /// Approves or rejects [requestId]. Returns whether it succeeded; either
  /// way the in-flight marker clears, and on success both lists refetch so
  /// the decided item moves from pending into history.
  Future<bool> decide(String requestId, {required bool approve}) async {
    state = state.copyWith(decidingIds: {...state.decidingIds, requestId});

    final result = await ref.read(
      decideApprovalUseCaseProvider,
    )((requestId: requestId, approve: approve));

    if (_disposed) return result.isSuccess;

    final remaining = {...state.decidingIds}..remove(requestId);
    state = state.copyWith(decidingIds: remaining);

    if (result.isSuccess) await _loadAll();
    return result.isSuccess;
  }

  AsyncValue<List<LeaveApproval>> _toAsync(Result<List<LeaveApproval>> result) =>
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (data) => AsyncValue.data(data),
      );
}

final leaveApprovalsNotifierProvider =
    NotifierProvider<LeaveApprovalsNotifier, LeaveApprovalsState>(
      LeaveApprovalsNotifier.new,
    );
