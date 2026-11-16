import 'dart:async';

import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/company_days_off.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_attachment.dart';
import 'package:next_on/features/time_off/domain/entities/leave_balance.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_history_query.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request_draft.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/domain/entities/uploaded_attachment.dart';
import 'package:next_on/features/time_off/domain/repositories/leave_repository.dart';
import 'package:next_on/features/time_off/domain/usecases/get_leave_approvals_usecase.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_attachment_notifier.dart';

/// The leave form's attachment slot, already holding [initial] — so a test
/// never opens a file chooser or uploads anything. Use it to override
/// `leaveAttachmentNotifierProvider`, which the form reads on submit.
class FixedLeaveAttachment extends LeaveAttachmentNotifier {
  FixedLeaveAttachment(this.initial);

  final UploadedAttachment? initial;

  @override
  FutureOr<UploadedAttachment?> build(String? arg) => initial;
}

/// Repository stand-in for the leave notifiers and widgets.
///
/// Same style as `FakeAttendanceRepository`: one settable [Result] per method,
/// answered every time that method is called (set it again between calls to
/// change the answer), and a list of what each call was given, so a test can
/// assert on the arguments as well as the count.
///
/// The default answers are fixed samples: `update` and `approve` answer
/// `req-1` whatever id they were sent. A test that reads the answer back sets
/// its own result.
class FakeLeaveRepository implements LeaveRepository {
  Result<List<LeaveType>> leaveTypesResult = Result.success([sampleLeaveType()]);
  /// The company's days off. None by default: every day is a working day.
  Result<CompanyDaysOff> companyDaysOffResult = const Result.success(
    CompanyDaysOff.none,
  );
  int companyDaysOffCalls = 0;
  Result<List<LeaveBalance>> balancesResult = const Result.success([]);

  /// Answers `balances(year)` for the years set here, in place of
  /// [balancesResult] — for a form that looks at more than one year.
  final Map<int, Result<List<LeaveBalance>>> balancesByYear = {};
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
  FutureResult<CompanyDaysOff> companyDaysOff() async {
    companyDaysOffCalls++;
    return companyDaysOffResult;
  }

  @override
  FutureResult<List<LeaveBalance>> balances(int year) async {
    balancesCalls.add(year);
    return balancesByYear[year] ?? balancesResult;
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

/// A company closed on Sundays, the commonest case.
const sundaysOff = CompanyDaysOff([
  RestDayRule(type: RestDayType.weekly, value: 'SUN'),
]);

/// A leave type with sane defaults: paid annual leave, switched on, whole
/// days only, no file needed. Override what the test is about.
LeaveType sampleLeaveType({
  String id = 'lt-annual',
  String code = 'annual',
  String name = 'Annual Leave',
  String? nameLo = 'ລາພັກປະຈຳປີ',
  String? color,
  bool isActive = true,
  double? maxDaysPerRequest,
  double? maxConsecutiveDays,
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
  isActive: isActive,
  maxDaysPerRequest: maxDaysPerRequest,
  maxConsecutiveDays: maxConsecutiveDays,
  minNoticeDays: minNoticeDays,
  allowHalfDay: allowHalfDay,
  requiresAttachment: requiresAttachment,
  allowNegativeBalance: allowNegativeBalance,
  isPaid: isPaid,
);

/// A leave request with sane defaults: two full days of annual leave, 18–19
/// November 2026 (one day, the 18th, for a half day), with the usual two-step
/// chain in the state that matches [status] — see [sampleLeaveSteps].
/// Override what the test is about.
LeaveRequest sampleLeaveRequest({
  String id = 'req-1',
  String employeeName = 'Noy Phommachanh',
  String? employeeNumber,
  String? departmentName,
  DateTime? createdAt,
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
      requestDays ??
      (durationType.isHalfDay
          ? [DateTime(2026, 11, 18)]
          : [DateTime(2026, 11, 18), DateTime(2026, 11, 19)]);
  final sorted = [...days]..sort();

  return LeaveRequest(
    id: id,
    employeeName: employeeName,
    employeeNumber: employeeNumber,
    departmentName: departmentName,
    createdAt: createdAt,
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
    steps: steps ?? sampleLeaveSteps(status),
    attachments: attachments,
  );
}

/// The usual chain, the department head then HR, in the state a request with
/// [status] is in:
///
/// * pending or cancelled — waiting on the department head;
/// * approved — both steps approved;
/// * rejected — the department head rejected it, and HR never saw it.
/// One leave type's balance for a year, with sane defaults: annual leave in
/// 2026, 15 days given, 5 used, 10 left.
LeaveBalance sampleLeaveBalance({
  String leaveTypeId = 'lt-annual',
  String leaveTypeName = 'Annual Leave',
  int year = 2026,
  double totalDays = 15,
  double usedDays = 5,
  double pendingDays = 0,
  double? remainingDays,
}) => LeaveBalance(
  leaveTypeId: leaveTypeId,
  leaveTypeName: leaveTypeName,
  year: year,
  totalDays: totalDays,
  usedDays: usedDays,
  pendingDays: pendingDays,
  remainingDays: remainingDays ?? totalDays - usedDays,
);

List<LeaveApprovalStep> sampleLeaveSteps([
  LeaveStatus status = LeaveStatus.pending,
]) {
  final (first, second) = switch (status) {
    LeaveStatus.approved => (LeaveStepStatus.approved, LeaveStepStatus.approved),
    LeaveStatus.rejected => (LeaveStepStatus.rejected, LeaveStepStatus.waiting),
    LeaveStatus.pending ||
    LeaveStatus.cancelled => (LeaveStepStatus.pending, LeaveStepStatus.waiting),
  };

  return [
    LeaveApprovalStep(
      id: 'step-1',
      stepNo: 1,
      role: LeaveStepRole.deptHead,
      approverName: 'Bounmy Sisavath',
      status: first,
    ),
    LeaveApprovalStep(
      id: 'step-2',
      stepNo: 2,
      role: LeaveStepRole.hr,
      status: second,
    ),
  ];
}

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
/// Older than [sampleLeaveRequest] and kept for the approval-card tests that
/// use it; new tests should prefer [sampleLeaveRequest].
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
