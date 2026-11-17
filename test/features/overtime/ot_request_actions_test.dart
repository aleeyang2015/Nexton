import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_request_actions.dart';

import '../../support/overtime_test_doubles.dart';

/// Which of Edit and Cancel the request page offers. They decide only what
/// shows: the server still decides, and its refusal is shown.
void main() {
  const me = 'emp-noy';

  OtStep step(int no, OtStepStatus status) => OtStep(
    id: 's$no',
    stepNo: no,
    role: no == 1 ? OtStepRole.deptHead : OtStepRole.hr,
    status: status,
  );

  OtRequestActions actions(OtRequest request, {String? own = me}) =>
      OtRequestActions.of(request, ownEmployeeId: own);

  test('pending, nothing approved yet: Edit and Cancel', () {
    final a = actions(
      sampleOt(
        'ot-1',
        steps: [step(1, OtStepStatus.pending), step(2, OtStepStatus.waiting)],
      ),
    );

    expect(a.canEdit, isTrue);
    expect(a.canCancel, isTrue);
    expect(a.askApprover, isFalse);
  });

  test('pending with a step approved: Cancel, no Edit', () {
    final a = actions(
      sampleOt(
        'ot-1',
        steps: [step(1, OtStepStatus.approved), step(2, OtStepStatus.pending)],
      ),
    );

    expect(a.canEdit, isFalse);
    expect(a.canCancel, isTrue);
  });

  test('a join of an HR post: Cancel, no Edit', () {
    final a = actions(sampleOt('ot-1', announcementId: 'post-1'));

    expect(a.canEdit, isFalse);
    expect(a.canCancel, isTrue);
  });

  test('approved: no buttons, and the "ask your approver" line', () {
    final a = actions(sampleOt('ot-1', status: OtStatus.approved));

    expect(a.canEdit, isFalse);
    expect(a.canCancel, isFalse);
    expect(a.askApprover, isTrue);
    expect(a.any, isFalse);
  });

  test('rejected, cancelled or unknown: nothing at all', () {
    for (final status in [
      OtStatus.rejected,
      OtStatus.cancelled,
      OtStatus.unknown,
    ]) {
      final a = actions(sampleOt('ot-1', status: status));
      expect(a.canEdit || a.canCancel || a.askApprover, isFalse, reason: '$status');
    }
  });

  test('someone else\'s request (a head opening his team member\'s): '
      'nothing', () {
    final theirs = sampleOt('ot-1', employeeId: 'emp-other');

    expect(actions(theirs).any, isFalse);
    expect(actions(theirs).askApprover, isFalse);
    expect(
      actions(sampleOt('ot-1', employeeId: 'emp-other', status: OtStatus.approved))
          .askApprover,
      isFalse,
    );
  });

  test('a request whose day is not known cannot be edited (the form would '
      'move it to today); Cancel stays', () {
    final noDay = OtRequest(
      id: 'ot-1',
      employeeId: me,
      startTime: '18:00',
      endTime: '20:00',
      status: OtStatus.pending,
    );

    expect(actions(noDay).canEdit, isFalse);
    expect(actions(noDay).canCancel, isTrue);
  });

  test('own employee id unknown (no staff record linked): nothing', () {
    expect(actions(sampleOt('ot-1'), own: null).any, isFalse);
    expect(actions(sampleOt('ot-1'), own: '').any, isFalse);
  });
}
