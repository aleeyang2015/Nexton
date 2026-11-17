import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

import '../../support/leave_test_doubles.dart';

/// Who gets the Approvals place, and which of its sections (decision 8:
/// department heads and HR only).
void main() {
  User user({
    bool head = false,
    List<String> roles = const ['employee'],
    List<String> permissions = const [],
    String? employeeId = 'emp-1',
  }) => User(
    id: 'u1',
    tenantId: 't1',
    email: 'a@b.la',
    firstName: 'A',
    lastName: 'B',
    roles: roles,
    permissions: permissions,
    employeeId: employeeId,
    isDepartmentHead: head,
  );

  const leaveHr = 'corehr:leaveRequest:manage';
  const attendanceHr = 'corehr:attendanceRecord:manage';

  test('plain staff: nothing', () {
    final a = ApproverAccess.of(user());
    expect(a.canApproveLeave, isFalse);
    expect(a.canApproveAttendance, isFalse);
    expect(a.canApproveOt, isFalse);
    expect(a.canSeeTeam, isFalse);
    expect(a.canSeeApprovals, isFalse);
  });

  test('a department head: everything', () {
    final a = ApproverAccess.of(user(head: true));
    expect(a.canApproveLeave, isTrue);
    expect(a.canApproveAttendance, isTrue);
    expect(a.canApproveOt, isTrue);
    expect(a.canSeeTeam, isTrue);
    expect(a.canSeeApprovals, isTrue);
  });

  for (final role in ['admin', 'super_admin', 'superadmin']) {
    test('the $role role: leave and attendance, not OT or the team', () {
      final a = ApproverAccess.of(user(roles: [role]));
      expect(a.isAdmin, isTrue);
      expect(a.canApproveLeave, isTrue);
      expect(a.canApproveAttendance, isTrue);
      expect(a.canApproveOt, isFalse);
      expect(a.canSeeTeam, isFalse);
      expect(a.canSeeApprovals, isTrue);
    });
  }

  test('a role that only looks like admin is not admin', () {
    expect(ApproverAccess.of(user(roles: ['Admin', 'hr_admin'])).isAdmin,
        isFalse);
  });

  test('leave HR permission: the leave section only', () {
    final a = ApproverAccess.of(user(permissions: [leaveHr]));
    expect(a.canApproveLeave, isTrue);
    expect(a.canApproveAttendance, isFalse);
    expect(a.canApproveOt, isFalse);
    expect(a.canSeeApprovals, isTrue);
  });

  test('attendance HR permission: off-site and "forgot to scan" only', () {
    final a = ApproverAccess.of(user(permissions: [attendanceHr]));
    expect(a.canApproveLeave, isFalse);
    expect(a.canApproveAttendance, isTrue);
    expect(a.canSeeApprovals, isTrue);
  });

  test('no staff record: no place, head or HR (they use the web)', () {
    expect(
      ApproverAccess.of(user(head: true, employeeId: null)).canSeeApprovals,
      isFalse,
    );
    expect(
      ApproverAccess.of(user(roles: ['admin'], employeeId: null))
          .canSeeApprovals,
      isFalse,
    );
    expect(
      ApproverAccess.of(user(head: true, employeeId: '')).canSeeApprovals,
      isFalse,
    );
  });

  test('no one signed in: nothing', () {
    expect(ApproverAccess.of(null).canSeeApprovals, isFalse);
    expect(ApproverAccess.of(null).canApproveLeave, isFalse);
  });

  group('canDecideLeave: the Approve and Reject buttons', () {
    // Bee's request, waiting on step [pendingNo]: 1 = Lee's dept-head step,
    // 2 = HR's.
    LeaveApprovalStep step(int no, LeaveStepRole role, LeaveStepStatus st,
        {String? approverId}) => LeaveApprovalStep(
      id: 'step-$no',
      stepNo: no,
      role: role,
      status: st,
      approverId: approverId,
    );

    final atHead = sampleLeaveRequest(
      employeeId: 'emp-bee',
      steps: [
        step(1, LeaveStepRole.deptHead, LeaveStepStatus.pending,
            approverId: 'emp-lee'),
        step(2, LeaveStepRole.hr, LeaveStepStatus.waiting),
      ],
    );
    final atHr = sampleLeaveRequest(
      employeeId: 'emp-bee',
      steps: [
        step(1, LeaveStepRole.deptHead, LeaveStepStatus.approved,
            approverId: 'emp-lee'),
        step(2, LeaveStepRole.hr, LeaveStepStatus.pending),
      ],
    );

    bool decide(request, User u) =>
        ApproverAccess.canDecideLeave(request, u);

    test('the head named on the waiting step: yes', () {
      expect(decide(atHead, user(head: true, employeeId: 'emp-lee')), isTrue);
    });

    test('a head not named on it: no', () {
      expect(decide(atHead, user(head: true, employeeId: 'emp-other')),
          isFalse);
    });

    test('HR rights on a dept-head step not theirs: no', () {
      expect(
        decide(atHead, user(permissions: [leaveHr], employeeId: 'emp-hr')),
        isFalse,
      );
    });

    test('an HR step: the leave permission or an admin role, yes', () {
      expect(decide(atHr, user(permissions: [leaveHr])), isTrue);
      expect(decide(atHr, user(roles: ['super_admin'])), isTrue);
    });

    test('an HR step: a plain head (the server says NOT_APPROVER), or staff '
        'with other rights, no', () {
      expect(decide(atHr, user(head: true, employeeId: 'emp-lee')), isFalse);
      expect(decide(atHr, user(permissions: [attendanceHr])), isFalse);
    });

    test('one\'s own request: no, even as HR or the named head', () {
      expect(
        decide(atHr, user(permissions: [leaveHr], employeeId: 'emp-bee')),
        isFalse,
      );
      final ownAtHead = sampleLeaveRequest(
        employeeId: 'emp-lee',
        steps: [
          step(1, LeaveStepRole.deptHead, LeaveStepStatus.pending,
              approverId: 'emp-lee'),
        ],
      );
      expect(decide(ownAtHead, user(head: true, employeeId: 'emp-lee')),
          isFalse);
    });

    test('not pending, or no step waiting: no', () {
      final approved = sampleLeaveRequest(
        employeeId: 'emp-bee',
        status: LeaveStatus.approved,
        steps: [step(1, LeaveStepRole.hr, LeaveStepStatus.pending)],
      );
      final noStep = sampleLeaveRequest(
        employeeId: 'emp-bee',
        steps: [step(1, LeaveStepRole.hr, LeaveStepStatus.waiting)],
      );
      expect(decide(approved, user(roles: ['admin'])), isFalse);
      expect(decide(noStep, user(roles: ['admin'])), isFalse);
    });

    test('no staff record: no (the web)', () {
      expect(decide(atHr, user(roles: ['admin'], employeeId: null)), isFalse);
    });

    test('a dept-head step with no approver sent: no', () {
      final unnamed = sampleLeaveRequest(
        employeeId: 'emp-bee',
        steps: [step(1, LeaveStepRole.deptHead, LeaveStepStatus.pending)],
      );
      expect(decide(unnamed, user(head: true, employeeId: 'emp-lee')),
          isFalse);
    });
  });
}
