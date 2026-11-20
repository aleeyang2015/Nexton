import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/leave_test_doubles.dart';
import '../../support/correction_approval_test_doubles.dart';
import '../../support/offsite_approval_test_doubles.dart';

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

    group('one person decides at most one step (#19, 16 Nov: the server '
        'answers 403 NOT_APPROVER)', () {
      test('a head with HR rights who approved step 1: no on the HR step', () {
        expect(
          decide(
            atHr,
            user(head: true, permissions: [leaveHr], employeeId: 'emp-lee'),
          ),
          isFalse,
        );
      });

      test('an admin who approved step 1: no on the HR step', () {
        expect(
          decide(atHr, user(roles: ['admin'], employeeId: 'emp-lee')),
          isFalse,
        );
      });

      test('HR, with step 1 approved by someone else: yes', () {
        expect(
          decide(atHr, user(permissions: [leaveHr], employeeId: 'emp-hr')),
          isTrue,
        );
      });

      test('approved step 1: no on a later step of any role', () {
        final threeSteps = sampleLeaveRequest(
          employeeId: 'emp-bee',
          steps: [
            step(1, LeaveStepRole.hr, LeaveStepStatus.approved,
                approverId: 'emp-hr'),
            step(2, LeaveStepRole.deptHead, LeaveStepStatus.approved,
                approverId: 'emp-lee'),
            step(3, LeaveStepRole.deptHead, LeaveStepStatus.pending,
                approverId: 'emp-hr'),
          ],
        );
        expect(
          decide(
            threeSteps,
            user(head: true, permissions: [leaveHr], employeeId: 'emp-hr'),
          ),
          isFalse,
        );
      });

      test('an approved step with no approver sent blocks nobody', () {
        final unnamedApproved = sampleLeaveRequest(
          employeeId: 'emp-bee',
          steps: [
            step(1, LeaveStepRole.deptHead, LeaveStepStatus.approved),
            step(2, LeaveStepRole.hr, LeaveStepStatus.pending),
          ],
        );
        expect(
          decide(unnamedApproved,
              user(permissions: [leaveHr], employeeId: 'emp-hr')),
          isTrue,
        );
      });
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

  group('canDecideAttendance: the Approve and Reject buttons (#46)', () {
    test('an HR step: HR by the attendance permission, or an admin', () {
      final scan = offsiteForApproval();
      expect(
        ApproverAccess.canDecideAttendance(scan, user(permissions: [attendanceHr])),
        isTrue,
      );
      expect(
        ApproverAccess.canDecideAttendance(scan, user(roles: ['admin'])),
        isTrue,
      );
      // A head, or HR for leave only, is not HR here.
      expect(ApproverAccess.canDecideAttendance(scan, user(head: true)), isFalse);
      expect(
        ApproverAccess.canDecideAttendance(scan, user(permissions: [leaveHr])),
        isFalse,
      );
    });

    test('a dept-head or specific step: the employee named on it', () {
      for (final role in [LeaveStepRole.deptHead, LeaveStepRole.unknown]) {
        final scan = offsiteForApproval(role: role, approverId: 'emp-1');
        expect(
          ApproverAccess.canDecideAttendance(scan, user(head: true)),
          isTrue,
          reason: '$role',
        );
        expect(
          ApproverAccess.canDecideAttendance(
            scan,
            user(head: true, employeeId: 'emp-2'),
          ),
          isFalse,
          reason: '$role',
        );
      }
    });

    test('a step that names no one yet is left to the server', () {
      final scan = offsiteForApproval(role: LeaveStepRole.deptHead);
      expect(ApproverAccess.canDecideAttendance(scan, user(head: true)), isTrue);
    });

    test('not after approving an earlier step (a head who is also HR)', () {
      final scan = offsiteForApproval().copyWithSteps([
        const TimeCorrectionApprovalStep(
          id: 's-1',
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          approverId: 'emp-1',
          status: LeaveStepStatus.approved,
        ),
        const TimeCorrectionApprovalStep(
          id: 's-2',
          stepNo: 2,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.pending,
        ),
      ]);
      expect(
        ApproverAccess.canDecideAttendance(
          scan,
          user(head: true, permissions: [attendanceHr]),
        ),
        isFalse,
      );
      // Someone else's earlier approval does not count.
      expect(
        ApproverAccess.canDecideAttendance(
          scan,
          user(permissions: [attendanceHr], employeeId: 'emp-2'),
        ),
        isTrue,
      );
    });

    test('never one\'s own request, even as HR', () {
      final scan = offsiteForApproval(employeeId: 'emp-1');
      expect(
        ApproverAccess.canDecideAttendance(scan, user(permissions: [attendanceHr])),
        isFalse,
      );
      expect(ApproverAccess.isOwnAttendance(scan, 'emp-1'), isTrue);
    });

    test('not once decided, nor with no step waiting, nor with no staff '
        'record', () {
      final hr = user(permissions: [attendanceHr]);
      expect(
        ApproverAccess.canDecideAttendance(
          offsiteForApproval(status: TimeCorrectionStatus.approved),
          hr,
        ),
        isFalse,
      );
      expect(
        ApproverAccess.canDecideAttendance(
          offsiteForApproval(stepStatus: LeaveStepStatus.approved),
          hr,
        ),
        isFalse,
      );
      expect(
        ApproverAccess.canDecideAttendance(
          offsiteForApproval(),
          user(permissions: [attendanceHr], employeeId: null),
        ),
        isFalse,
      );
    });
  });

  group('canDecideAttendance on a "forgot to scan" (#47)', () {
    test('the same rule: HR step for HR, head step for its head, never own',
        () {
      final hrStep = correctionForApproval();
      expect(
        ApproverAccess.canDecideAttendance(
          hrStep,
          user(permissions: [attendanceHr]),
        ),
        isTrue,
      );
      expect(
        ApproverAccess.canDecideAttendance(hrStep, user(head: true)),
        isFalse,
      );
      final headStep = correctionForApproval(
        role: LeaveStepRole.deptHead,
        approverId: 'emp-1',
      );
      expect(
        ApproverAccess.canDecideAttendance(headStep, user(head: true)),
        isTrue,
      );
      expect(
        ApproverAccess.canDecideAttendance(
          correctionForApproval(employeeId: 'emp-1'),
          user(permissions: [attendanceHr]),
        ),
        isFalse,
      );
    });
  });

  group('OT (#49): who gets Approve / Reject, and Cancel', () {
    OtStep otStep(
      int no,
      OtStepRole role,
      OtStepStatus status, {
      String? approverId,
    }) => OtStep(
      id: 's-$no',
      stepNo: no,
      role: role,
      status: status,
      approverId: approverId,
    );

    OtRequest ot({
      OtStatus status = OtStatus.pending,
      String employeeId = 'emp-staff',
      List<OtStep> steps = const [],
      DateTime? startsAt,
    }) => OtRequest(
      id: 'ot-1',
      employeeId: employeeId,
      startTime: '18:00',
      endTime: '20:00',
      status: status,
      steps: steps,
      startsAt: startsAt,
    );

    final head = user(head: true);

    test('canDecideOt: a pending head or specific step naming me', () {
      for (final role in [OtStepRole.deptHead, OtStepRole.unknown]) {
        expect(
          ApproverAccess.canDecideOt(
            ot(steps: [otStep(1, role, OtStepStatus.pending, approverId: 'emp-1')]),
            head,
          ),
          isTrue,
          reason: '$role',
        );
      }
    });

    test('canDecideOt: not another head\'s step, not an HR step (even for '
        'HR), not my own, not decided', () {
      expect(
        ApproverAccess.canDecideOt(
          ot(steps: [otStep(1, OtStepRole.deptHead, OtStepStatus.pending, approverId: 'emp-9')]),
          head,
        ),
        isFalse,
      );
      expect(
        ApproverAccess.canDecideOt(
          ot(steps: [otStep(1, OtStepRole.hr, OtStepStatus.pending, approverId: 'emp-1')]),
          user(head: true, roles: ['admin'], permissions: [attendanceHr]),
        ),
        isFalse,
      );
      expect(
        ApproverAccess.canDecideOt(
          ot(
            employeeId: 'emp-1',
            steps: [otStep(1, OtStepRole.deptHead, OtStepStatus.pending, approverId: 'emp-1')],
          ),
          head,
        ),
        isFalse,
      );
      expect(
        ApproverAccess.canDecideOt(
          ot(
            status: OtStatus.approved,
            steps: [otStep(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'emp-1')],
          ),
          head,
        ),
        isFalse,
      );
    });

    test('canDecideOt: not after I approved an earlier step (the server '
        'refuses it)', () {
      expect(
        ApproverAccess.canDecideOt(
          ot(
            steps: [
              otStep(1, OtStepRole.unknown, OtStepStatus.approved, approverId: 'emp-1'),
              otStep(2, OtStepRole.deptHead, OtStepStatus.pending, approverId: 'emp-1'),
            ],
          ),
          head,
        ),
        isFalse,
      );
    });

    test('canCancelApprovedOt: an HR step I approved on the web adds '
        'nothing', () {
      expect(
        ApproverAccess.canCancelApprovedOt(
          ot(
            status: OtStatus.approved,
            startsAt: DateTime.utc(2026, 11, 14, 11),
            steps: [
              otStep(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'emp-9'),
              otStep(2, OtStepRole.hr, OtStepStatus.approved, approverId: 'emp-1'),
            ],
          ),
          head,
          DateTime.utc(2026, 11, 13),
        ),
        isFalse,
      );
    });

    group('canCancelApprovedOt around starts_at', () {
      final startsAt = DateTime.utc(2026, 11, 14, 11);
      final approvedByMe = ot(
        status: OtStatus.approved,
        startsAt: startsAt,
        steps: [
          otStep(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'emp-1'),
          otStep(2, OtStepRole.hr, OtStepStatus.approved, approverId: 'emp-hr'),
        ],
      );

      test('a second before: yes; at it or after: no', () {
        expect(
          ApproverAccess.canCancelApprovedOt(
            approvedByMe,
            head,
            startsAt.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          ApproverAccess.canCancelApprovedOt(approvedByMe, head, startsAt),
          isFalse,
        );
        expect(
          ApproverAccess.canCancelApprovedOt(
            approvedByMe,
            head,
            startsAt.add(const Duration(minutes: 1)),
          ),
          isFalse,
        );
      });

      test('not when I approved no step, nor before it is approved', () {
        final before = startsAt.subtract(const Duration(days: 1));
        expect(
          ApproverAccess.canCancelApprovedOt(
            approvedByMe,
            user(head: true, employeeId: 'emp-9'),
            before,
          ),
          isFalse,
        );
        expect(
          ApproverAccess.canCancelApprovedOt(
            ot(
              startsAt: startsAt,
              steps: [otStep(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'emp-1')],
            ),
            head,
            before,
          ),
          isFalse,
        );
      });
    });
  });

  group('opensAsApprover: a push opened someone else\'s request (#53)', () {
    const me = 'b3f1-employees-uuid';

    for (final (label, owner, user, attendance, expected)
        in <(String, String?, User?, bool, bool)>[
          (
            'a head, someone else\'s leave',
            'other',
            approverTestUser(),
            false,
            true,
          ),
          ('a head, my own leave', me, approverTestUser(), false, false),
          (
            'a head, someone else\'s correction',
            'other',
            approverTestUser(),
            true,
            true,
          ),
          ('no owner in the answer', null, approverTestUser(), false, false),
          ('an empty owner', '', approverTestUser(), false, false),
          ('no one signed in', 'other', null, false, false),
          (
            'a login with no staff record',
            'other',
            approverTestUser(employeeId: null),
            false,
            false,
          ),
          (
            'a plain employee',
            'other',
            approverTestUser(head: false),
            false,
            false,
          ),
          (
            'leave HR on a correction',
            'other',
            approverTestUser(
              head: false,
              permissions: const [ApproverAccess.leaveManagePermission],
            ),
            true,
            false,
          ),
          (
            'leave HR on leave',
            'other',
            approverTestUser(
              head: false,
              permissions: const [ApproverAccess.leaveManagePermission],
            ),
            false,
            true,
          ),
        ]) {
      test(label, () {
        expect(
          ApproverAccess.opensAsApprover(
            ownerId: owner,
            user: user,
            attendance: attendance,
          ),
          expected,
        );
      });
    }
  });
}
