import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/data/models/leave_request_step_model.dart';

/// Who a step's approver is (`steps[].approver.id`): what tells a head
/// whether the waiting step is theirs to decide.
void main() {
  Map<String, dynamic> step(Object? approver) => {
    'id': 's1',
    'step_no': 1,
    'step_role': 'dept_head',
    'status': 'pending',
    'approver': approver,
  };

  test('approver.id is read with the name', () {
    final s = LeaveRequestStepModel.fromJson(
      step({'id': 'emp-head', 'name': 'Lee'}),
    );
    expect(s.approverId, 'emp-head');
    expect(s.approverName, 'Lee');
  });

  test('no approver yet (an HR step not decided): both null', () {
    final s = LeaveRequestStepModel.fromJson(step(null));
    expect(s.approverId, isNull);
    expect(s.approverName, isNull);
  });

  test('an empty or non-string id reads as none', () {
    expect(LeaveRequestStepModel.fromJson(step({'id': ''})).approverId, isNull);
    expect(LeaveRequestStepModel.fromJson(step({'id': 7})).approverId, isNull);
  });
}
