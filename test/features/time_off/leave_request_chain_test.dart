import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  group('where a pending request stands in the dept-head -> HR chain', () {
    test('nobody has approved while it sits with its first approver', () {
      final request = pendingApproval();

      expect(request.awaitsFirstApproval, isTrue);
      expect(request.lastApprovedStep, isNull);
      expect(request.isFinalApprovalStep, isFalse);
    });

    test('HR deciding after the dept head is the final say', () {
      final request = pendingApproval(clearedByDeptHead: true);

      expect(request.awaitsFirstApproval, isFalse);
      expect(request.lastApprovedStep?.role, LeaveStepRole.deptHead);
      expect(request.isFinalApprovalStep, isTrue);
    });

    test('the latest approval wins when several steps have passed', () {
      final request = _withSteps(const [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.approved,
        ),
        LeaveApprovalStep(
          stepNo: 2,
          role: LeaveStepRole.unknown,
          status: LeaveStepStatus.approved,
        ),
        LeaveApprovalStep(
          stepNo: 3,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.pending,
        ),
      ]);

      expect(request.lastApprovedStep?.stepNo, 2);
      expect(request.isFinalApprovalStep, isTrue);
    });

    test('a chain that never arrived is not assumed to be final', () {
      final request = _withSteps(const []);

      expect(request.awaitsFirstApproval, isTrue);
      expect(request.isFinalApprovalStep, isFalse);
    });

    test('a single-step chain is final on its only step', () {
      final request = _withSteps(const [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.pending,
        ),
      ]);

      expect(request.isFinalApprovalStep, isTrue);
      expect(request.awaitsFirstApproval, isTrue);
    });
  });
}

LeaveRequest _withSteps(List<LeaveApprovalStep> steps) => LeaveRequest(
  id: 'r-1',
  employeeName: 'Noy Phommachanh',
  leaveType: const LeaveType(id: 'lt-1', code: 'annual', name: 'Annual'),
  startDate: DateTime(2026, 9, 14),
  endDate: DateTime(2026, 9, 15),
  totalDays: 2,
  status: LeaveStatus.pending,
  steps: steps,
);
