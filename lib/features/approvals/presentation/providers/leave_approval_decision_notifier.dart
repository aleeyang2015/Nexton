import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';

import '../../../time_off/data/datasources/leave_error_code.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/presentation/providers/leave_approvals_notifier.dart';
import '../../../time_off/presentation/providers/leave_approvals_state.dart';
import '../../../time_off/presentation/providers/leave_request_detail_notifier.dart';
import '../../../time_off/time_off_providers.dart';

/// Approve or reject from the approver's page of one leave request, by its
/// id. The state is true while a decision is on its way, so the buttons
/// switch off and a second tap sends nothing.
///
/// After a decision the approvals lists are reloaded (when open). A refusal
/// that says the page is out of date (the step changed, it was decided,
/// not the caller's step, gone) reloads the page too, so the new status
/// shows and the buttons go.
class LeaveApprovalDecisionNotifier
    extends AutoDisposeFamilyNotifier<bool, String> {
  bool _disposed = false;

  @override
  bool build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return false;
  }

  /// Approves the waiting step, with [note] when one was typed.
  Future<LeaveDecisionOutcome> approve(LeaveRequest request, {String? note}) {
    final trimmed = note?.trim();
    return _decide(
      () => ref.read(approveLeaveStepUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
      )),
    );
  }

  /// Rejects the waiting step with [reason].
  Future<LeaveDecisionOutcome> reject(LeaveRequest request, String reason) {
    return _decide(
      () => ref.read(rejectLeaveStepUseCaseProvider)((
        id: request.id,
        reason: reason,
        stepId: request.currentStep?.id,
        note: null,
      )),
    );
  }

  Future<LeaveDecisionOutcome> _decide(
    Future<Result<LeaveRequest>> Function() action,
  ) async {
    if (state) return LeaveDecisionOutcome.gone;
    state = true;

    final result = await action();
    if (!_disposed) state = false;

    return result.fold(
      (failure) async {
        if (!LeaveErrorCode.isStaleForApprover(failure)) {
          return LeaveDecisionOutcome.failed(failure);
        }
        _reloadLists();
        final detail = leaveRequestDetailNotifierProvider(arg);
        if (!_disposed && ref.exists(detail)) {
          await ref.read(detail.notifier).refresh();
        }
        return LeaveDecisionOutcome.reloaded(failure);
      },
      (_) async {
        _reloadLists();
        return LeaveDecisionOutcome.success;
      },
    );
  }

  /// The two lists underneath, when they are open. Not once this page has
  /// closed: the lists reload when opened again.
  void _reloadLists() {
    if (_disposed || !ref.exists(leaveApprovalsNotifierProvider)) return;
    ref.read(leaveApprovalsNotifierProvider.notifier).retry();
  }
}

final leaveApprovalDecisionNotifierProvider = NotifierProvider.autoDispose
    .family<LeaveApprovalDecisionNotifier, bool, String>(
      LeaveApprovalDecisionNotifier.new,
    );
