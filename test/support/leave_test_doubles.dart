import 'dart:async';

import 'package:next_on/core/network/paged_list.dart';
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
import 'package:next_on/features/time_off/domain/repositories/leave_repository.dart';
import 'package:next_on/features/time_off/domain/usecases/get_leave_approvals_usecase.dart';

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

  /// When set, answers each history page by itself (for tests of loading
  /// more); otherwise [myRequestsResult] is the one and only page.
  FutureResult<CursorPage<LeaveRequest>> Function(
    LeaveHistoryQuery query,
    String? cursor,
  )?
  myRequestsPage;

  /// The cursor each history call was made with, in order; null for a
  /// first page.
  final List<String?> myRequestsCursors = [];
  /// The caller's waiting request; none by default.
  Result<LeaveRequest?> pendingRequestResult = const Result.success(null);
  int pendingRequestCalls = 0;
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

  /// Answers `myApprovals(status: approved)`: what the caller approved.
  Result<List<LeaveRequest>> approvedByMeResult = const Result.success([]);

  /// Answers `myApprovals(status: rejected)`: what the caller rejected.
  Result<List<LeaveRequest>> rejectedByMeResult = const Result.success([]);

  /// When set, answers each approvals page by itself (for tests of loading
  /// more); otherwise the three lists above are each one whole page.
  FutureResult<CursorPage<LeaveRequest>> Function(
    LeaveStatus? status,
    String? cursor,
  )?
  myApprovalsPage;

  /// The cursor each approvals call was made with, in order.
  final List<String?> myApprovalsCursors = [];

  /// Answers `teamRequests` (#50); by default one empty page.
  FutureResult<CursorPage<LeaveRequest>> Function(
    LeaveStatus? status,
    String? cursor,
  )
  teamPage = (status, cursor) async =>
      const Result.success(CursorPage.single(<LeaveRequest>[]));

  /// What each team call asked for, in order.
  final List<({LeaveStatus? status, String? cursor})> teamCalls = [];

  @override
  FutureResult<CursorPage<LeaveRequest>> teamRequests({
    LeaveStatus? status,
    String? cursor,
  }) {
    teamCalls.add((status: status, cursor: cursor));
    return teamPage(status, cursor);
  }
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
  FutureResult<LeaveRequest?> pendingRequest() async {
    pendingRequestCalls++;
    return pendingRequestResult;
  }

  @override
  FutureResult<CursorPage<LeaveRequest>> myRequests(
    LeaveHistoryQuery query, {
    String? cursor,
  }) async {
    myRequestsCalls.add(query);
    myRequestsCursors.add(cursor);

    final page = myRequestsPage;
    if (page != null) return page(query, cursor);
    // The plain list is the whole answer: one page, nothing after it.
    return myRequestsResult.mapData(CursorPage.single);
  }

  @override
  FutureResult<LeaveRequest> requestDetail(String id) async {
    requestDetailCalls.add(id);
    return requestDetailResult;
  }

  @override
  FutureResult<LeaveRequest> submit(LeaveRequestDraft draft) async {
    submitCalls.add(draft);
    final answer = submitResult;
    final hold = holdSubmit;
    holdSubmit = null;
    await hold?.future;
    return answer;
  }

  /// When set, the next `submit` waits for it before answering.
  Completer<void>? holdSubmit;

  @override
  FutureResult<LeaveRequest> update(String id, LeaveRequestDraft draft) async {
    updateCalls.add((id: id, draft: draft));
    final answer = updateResult;
    final hold = holdUpdate;
    holdUpdate = null;
    await hold?.future;
    return answer;
  }

  /// When set, the next [update] waits for it (the save still on its way).
  Completer<void>? holdUpdate;

  @override
  FutureResult<LeaveRequest> cancel(String id) async {
    cancelCalls.add(id);
    return cancelResult;
  }

  @override
  FutureResult<CursorPage<LeaveRequest>> myApprovals({
    LeaveStatus? status,
    String? cursor,
  }) async {
    myApprovalsCalls.add(status);
    myApprovalsCursors.add(cursor);

    final page = myApprovalsPage;
    if (page != null) return page(status, cursor);
    final list = switch (status) {
      LeaveStatus.pending => pendingApprovalsResult,
      LeaveStatus.rejected => rejectedByMeResult,
      _ => approvedByMeResult,
    };
    return list.mapData(CursorPage.single);
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
  String? employeeId,
  String employeeName = 'Noy Phommachanh',
  String? employeeNumber,
  String? departmentName,
  String? departmentId,
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
    employeeId: employeeId,
    employeeName: employeeName,
    employeeNumber: employeeNumber,
    departmentName: departmentName,
    departmentId: departmentId,
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
  FutureResult<CursorPage<LeaveRequest>> call(
    LeaveApprovalsPageParams params,
  ) async =>
      (params.status == LeaveStatus.pending
              ? pending
              : (history ?? const Result.success(<LeaveRequest>[])))
          .mapData(CursorPage.single);
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
