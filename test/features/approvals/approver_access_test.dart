import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';

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
}
