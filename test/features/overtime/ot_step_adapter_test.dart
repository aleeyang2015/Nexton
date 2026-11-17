import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_step_adapter.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

/// OT steps drawn by the leave timeline (#17): the same roles, statuses,
/// names, notes and decision times.
void main() {
  OtStep step({
    OtStepRole role = OtStepRole.deptHead,
    OtStepStatus status = OtStepStatus.pending,
    String? approverName,
    String? note,
    DateTime? actedAt,
  }) => OtStep(
    id: 's-1',
    stepNo: 2,
    role: role,
    approverId: approverName == null ? null : 'u-1',
    approverName: approverName,
    status: status,
    note: note,
    actedAt: actedAt,
  );

  test('every field the timeline reads is carried over', () {
    final at = DateTime(2026, 11, 11, 14, 5);
    final leave = OtStepAdapter.toLeaveStep(
      step(
        status: OtStepStatus.approved,
        approverName: 'Somchai K.',
        note: 'OK',
        actedAt: at,
      ),
    );

    expect(leave.id, 's-1');
    expect(leave.stepNo, 2);
    expect(leave.role, LeaveStepRole.deptHead);
    expect(leave.status, LeaveStepStatus.approved);
    expect(leave.approverName, 'Somchai K.');
    expect(leave.note, 'OK');
    expect(leave.decidedAt, at);
  });

  test('roles: head, HR, and one the App does not know', () {
    expect(
      OtStepAdapter.toLeaveStep(step(role: OtStepRole.hr)).role,
      LeaveStepRole.hr,
    );
    expect(
      OtStepAdapter.toLeaveStep(step(role: OtStepRole.unknown)).role,
      LeaveStepRole.unknown,
    );
  });

  test('statuses; one the App does not know is drawn as not reached', () {
    for (final (ot, leave) in [
      (OtStepStatus.waiting, LeaveStepStatus.waiting),
      (OtStepStatus.pending, LeaveStepStatus.pending),
      (OtStepStatus.approved, LeaveStepStatus.approved),
      (OtStepStatus.rejected, LeaveStepStatus.rejected),
      (OtStepStatus.unknown, LeaveStepStatus.waiting),
    ]) {
      expect(OtStepAdapter.toLeaveStep(step(status: ot)).status, leave);
    }
  });

  test('a step with no approver keeps no name: the timeline shows its role',
      () {
    expect(OtStepAdapter.toLeaveStep(step()).approverName, isNull);
  });

  test('the request status, for the timeline\'s cancelled end; unknown is '
      'none', () {
    expect(OtStepAdapter.toLeaveStatus(OtStatus.pending), LeaveStatus.pending);
    expect(OtStepAdapter.toLeaveStatus(OtStatus.approved), LeaveStatus.approved);
    expect(OtStepAdapter.toLeaveStatus(OtStatus.rejected), LeaveStatus.rejected);
    expect(
      OtStepAdapter.toLeaveStatus(OtStatus.cancelled),
      LeaveStatus.cancelled,
    );
    expect(OtStepAdapter.toLeaveStatus(OtStatus.unknown), isNull);
  });
}
