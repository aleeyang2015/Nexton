import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  group('canEdit', () {
    test('only while pending', () {
      expect(sampleLeaveRequest(status: LeaveStatus.pending).canEdit, isTrue);
      for (final status in const [
        LeaveStatus.approved,
        LeaveStatus.rejected,
        LeaveStatus.cancelled,
      ]) {
        expect(
          sampleLeaveRequest(status: status).canEdit,
          isFalse,
          reason: '$status',
        );
      }
    });
  });

  group('canCancel', () {
    test('while pending or approved', () {
      expect(sampleLeaveRequest(status: LeaveStatus.pending).canCancel, isTrue);
      expect(
        sampleLeaveRequest(status: LeaveStatus.approved).canCancel,
        isTrue,
      );
    });

    test('not once rejected or cancelled', () {
      expect(
        sampleLeaveRequest(status: LeaveStatus.rejected).canCancel,
        isFalse,
      );
      expect(
        sampleLeaveRequest(status: LeaveStatus.cancelled).canCancel,
        isFalse,
      );
    });
  });

  group('currentStep', () {
    test('is the pending step', () {
      final request = sampleLeaveRequest();

      expect(request.currentStep?.id, 'step-1');
      expect(request.currentStep?.role, LeaveStepRole.deptHead);
    });

    test('moves on once the first step is approved', () {
      final request = sampleLeaveRequest(
        steps: const [
          LeaveApprovalStep(
            id: 'step-1',
            stepNo: 1,
            role: LeaveStepRole.deptHead,
            status: LeaveStepStatus.approved,
          ),
          LeaveApprovalStep(
            id: 'step-2',
            stepNo: 2,
            role: LeaveStepRole.hr,
            status: LeaveStepStatus.pending,
          ),
        ],
      );

      expect(request.currentStep?.id, 'step-2');
      expect(request.lastApprovedStep?.id, 'step-1');
      expect(request.awaitsFirstApproval, isFalse);
      expect(request.isFinalApprovalStep, isTrue);
    });

    test('is null when no step is pending', () {
      final decided = sampleLeaveRequest(
        status: LeaveStatus.approved,
        steps: const [
          LeaveApprovalStep(
            stepNo: 1,
            role: LeaveStepRole.hr,
            status: LeaveStepStatus.approved,
          ),
        ],
      );

      expect(decided.currentStep, isNull);
      expect(sampleLeaveRequest(steps: const []).currentStep, isNull);
    });

    test('at the first of two steps, approving is not final', () {
      final request = sampleLeaveRequest();

      expect(request.awaitsFirstApproval, isTrue);
      expect(request.isFinalApprovalStep, isFalse);
    });
  });

  group('rejectionNote', () {
    test('is the note on the rejected step', () {
      final request = sampleLeaveRequest(
        status: LeaveStatus.rejected,
        steps: const [
          LeaveApprovalStep(
            stepNo: 1,
            role: LeaveStepRole.deptHead,
            status: LeaveStepStatus.approved,
            note: 'fine by me',
          ),
          LeaveApprovalStep(
            stepNo: 2,
            role: LeaveStepRole.hr,
            status: LeaveStepStatus.rejected,
            note: 'No cover that week',
          ),
        ],
      );

      expect(request.rejectionNote, 'No cover that week');
    });

    test('is null when the rejection carries no note, or nothing was '
        'rejected', () {
      final noNote = sampleLeaveRequest(
        status: LeaveStatus.rejected,
        steps: const [
          LeaveApprovalStep(
            stepNo: 1,
            role: LeaveStepRole.hr,
            status: LeaveStepStatus.rejected,
            note: '',
          ),
        ],
      );

      expect(noNote.rejectionNote, isNull);
      expect(sampleLeaveRequest().rejectionNote, isNull);
    });
  });

  group('the sample builders', () {
    test('give a request whose days, range and total agree', () {
      final request = sampleLeaveRequest();

      expect(request.startDate, DateTime(2026, 11, 18));
      expect(request.endDate, DateTime(2026, 11, 19));
      expect(request.totalDays, 2);
      expect(request.isPending, isTrue);
      expect(request.currentStepNo, 1);
    });

    test('give a leave type that asks for nothing special', () {
      final type = sampleLeaveType();

      expect(type.allowHalfDay, isFalse);
      expect(type.requiresAttachment, isFalse);
      expect(type.isPaid, isTrue);
    });
  });
}
