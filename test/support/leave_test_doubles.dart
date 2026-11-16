import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_attachment.dart';
import 'package:next_on/features/time_off/domain/entities/leave_balance.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_history_query.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request_draft.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/domain/repositories/leave_repository.dart';
import 'package:next_on/features/time_off/domain/usecases/get_leave_approvals_usecase.dart';

/// Repository stand-in for the leave notifiers and widgets.
///
/// Same style as `FakeAttendanceRepository`: one settable [Result] per method,
/// answered every time that method is called, and a list of what each call
/// was given, so a test can assert on the arguments as well as the count.
class FakeLeaveRepository implements LeaveRepository {
  Result<List<LeaveType>> leaveTypesResult = Result.success([sampleLeaveType()]);
  Result<List<LeaveBalance>> balancesResult = const Result.success([]);
  Result<List<LeaveRequest>> myRequestsResult = const Result.success([]);
  Result<LeaveRequest> requestDetailResult = Result.success(
    sampleLeaveRequest(),
  );
  Result<LeaveRequest> submitResult = Result.success(sampleLeaveRequest());
  Result<LeaveRequest> updateResult = Result.success(sampleLeaveRequest());
  Result<LeaveRequest> cancelResult = Result.success(
    sampleLeaveRequest(status: LeaveStatus.cancelled),
  );

  /// Answers `myApprovals(status: pending)`.
  Result<List<LeaveRequest>> pendingApprovalsResult = const Result.success([]);

  /// Answers `myApprovals()` with any other status, the unfiltered call
  /// included.
  Result<List<LeaveRequest>> allApprovalsResult = const Result.success([]);
  Result<LeaveRequest> approveResult = Result.success(
    sampleLeaveRequest(status: LeaveStatus.approved),
  );
  Result<LeaveRequest> rejectResult = Result.success(
    sampleLeaveRequest(status: LeaveStatus.rejected),
  );

  int leaveTypesCalls = 0;
  final List<int> balancesCalls = [];
  final List<LeaveHistoryQuery> myRequestsCalls = [];
  final List<String> requestDetailCalls = [];
  final List<LeaveRequestDraft> submitCalls = [];
  final List<({String id, LeaveRequestDraft draft})> updateCalls = [];
  final List<String> cancelCalls = [];
  final List<LeaveStatus?> myApprovalsCalls = [];
  final List<({String id, String? stepId, String? note})> approveCalls = [];
  final List<({String id, String reason, String? stepId, String? note})>
  rejectCalls = [];

  @override
  FutureResult<List<LeaveType>> leaveTypes() async {
    leaveTypesCalls++;
    return leaveTypesResult;
  }

  @override
  FutureResult<List<LeaveBalance>> balances(int year) async {
    balancesCalls.add(year);
    return balancesResult;
  }

  @override
  FutureResult<List<LeaveRequest>> myRequests(LeaveHistoryQuery query) async {
    myRequestsCalls.add(query);
    return myRequestsResult;
  }

  @override
  FutureResult<LeaveRequest> requestDetail(String id) async {
    requestDetailCalls.add(id);
    return requestDetailResult;
  }

  @override
  FutureResult<LeaveRequest> submit(LeaveRequestDraft draft) async {
    submitCalls.add(draft);
    return submitResult;
  }

  @override
  FutureResult<LeaveRequest> update(String id, LeaveRequestDraft draft) async {
    updateCalls.add((id: id, draft: draft));
    return updateResult;
  }

  @override
  FutureResult<LeaveRequest> cancel(String id) async {
    cancelCalls.add(id);
    return cancelResult;
  }

  @override
  FutureResult<List<LeaveRequest>> myApprovals({LeaveStatus? status}) async {
    myApprovalsCalls.add(status);
    return status == LeaveStatus.pending
        ? pendingApprovalsResult
        : allApprovalsResult;
  }

  @override
  FutureResult<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  }) async {
    approveCalls.add((id: id, stepId: stepId, note: note));
    return approveResult;
  }

  @override
  FutureResult<LeaveRequest> reject({
    required String id,
    required String reason,
    String? stepId,
    String? note,
  }) async {
    rejectCalls.add((id: id, reason: reason, stepId: stepId, note: note));
    return rejectResult;
  }
}

/// A leave type with sane defaults: paid annual leave, whole days only, no
/// file needed. Override what the test is about.
LeaveType sampleLeaveType({
  String id = 'lt-annual',
  String code = 'annual',
  String name = 'Annual Leave',
  String? nameLo = 'ລາພັກປະຈຳປີ',
  String? color,
  int? maxDaysPerRequest,
  int? maxConsecutiveDays,
  int? minNoticeDays,
  bool allowHalfDay = false,
  bool requiresAttachment = false,
  bool allowNegativeBalance = false,
  bool isPaid = true,
}) => LeaveType(
  id: id,
  code: code,
  name: name,
  nameLo: nameLo,
  color: color,
  maxDaysPerRequest: maxDaysPerRequest,
  maxConsecutiveDays: maxConsecutiveDays,
  minNoticeDays: minNoticeDays,
  allowHalfDay: allowHalfDay,
  requiresAttachment: requiresAttachment,
  allowNegativeBalance: allowNegativeBalance,
  isPaid: isPaid,
);

/// A leave request with sane defaults: two full days of annual leave, 18–19
/// November 2026, pending at the first of two steps. Override what the test
/// is about.
LeaveRequest sampleLeaveRequest({
  String id = 'req-1',
  String employeeName = 'Noy Phommachanh',
  LeaveType? leaveType,
  List<DateTime>? requestDays,
  DateTime? returnDate,
  double? totalDays,
  LeaveDurationType durationType = LeaveDurationType.fullDay,
  String reason = '',
  LeaveStatus status = LeaveStatus.pending,
  int? currentStepNo,
  List<LeaveApprovalStep>? steps,
  List<LeaveAttachment> attachments = const [],
}) {
  final days =
      requestDays ?? [DateTime(2026, 11, 18), DateTime(2026, 11, 19)];
  final sorted = [...days]..sort();

  return LeaveRequest(
    id: id,
    employeeName: employeeName,
    leaveType: leaveType ?? sampleLeaveType(),
    startDate: sorted.first,
    endDate: sorted.last,
    requestDays: days,
    returnDate: returnDate,
    totalDays: totalDays ?? (durationType.isHalfDay ? 0.5 : days.length.toDouble()),
    durationType: durationType,
    reason: reason,
    status: status,
    currentStepNo: currentStepNo ?? (status == LeaveStatus.pending ? 1 : null),
    steps: steps ?? sampleLeaveSteps(),
    attachments: attachments,
  );
}

/// The usual chain: the department head first (pending), then HR (waiting).
List<LeaveApprovalStep> sampleLeaveSteps() => const [
  LeaveApprovalStep(
    id: 'step-1',
    stepNo: 1,
    role: LeaveStepRole.deptHead,
    approverName: 'Bounmy Sisavath',
    status: LeaveStepStatus.pending,
  ),
  LeaveApprovalStep(
    id: 'step-2',
    stepNo: 2,
    role: LeaveStepRole.hr,
    status: LeaveStepStatus.waiting,
  ),
];

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
