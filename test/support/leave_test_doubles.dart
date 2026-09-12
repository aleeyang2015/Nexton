import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/domain/usecases/get_leave_approvals_usecase.dart';

/// Answers the approvals tab's two queries: [pending] for
/// `status == pending`, [history] for the unfiltered call the notifier makes
/// straight after.
class FakeGetLeaveApprovals implements GetLeaveApprovalsUseCase {
  FakeGetLeaveApprovals({required this.pending, this.history});

  final Result<List<LeaveRequest>> pending;
  final Result<List<LeaveRequest>>? history;

  @override
  FutureResult<List<LeaveRequest>> call(LeaveStatus? status) async =>
      status == LeaveStatus.pending
      ? pending
      : (history ?? const Result.success([]));
}

/// A pending request sitting at the given point of the dept-head → HR chain.
///
/// [clearedByDeptHead] false leaves it with its first approver; true marks
/// the dept-head step approved and hands it to HR, which is the shape that
/// should read as a final approval.
LeaveRequest pendingApproval({
  String id = 'r-1',
  String employeeName = 'Noy Phommachanh',
  String reason = '',
  bool clearedByDeptHead = false,
}) {
  return LeaveRequest(
    id: id,
    employeeName: employeeName,
    leaveType: const LeaveType(id: 'lt-1', code: 'annual', name: 'Annual'),
    startDate: DateTime(2026, 9, 14),
    endDate: DateTime(2026, 9, 15),
    totalDays: 2,
    reason: reason,
    status: LeaveStatus.pending,
    currentStepNo: clearedByDeptHead ? 2 : 1,
    steps: [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: clearedByDeptHead
            ? LeaveStepStatus.approved
            : LeaveStepStatus.pending,
      ),
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: clearedByDeptHead
            ? LeaveStepStatus.pending
            : LeaveStepStatus.waiting,
      ),
    ],
  );
}
