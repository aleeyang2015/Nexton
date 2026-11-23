import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_form_rules.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';

import '../../support/leave_test_doubles.dart';

/// Which parts of the day the form offers (#14).
void main() {
  final halfDays = sampleLeaveType(id: 'lt-personal', allowHalfDay: true);
  final wholeDays = sampleLeaveType();

  LeaveRequestFormState on(LeaveDurationType type) =>
      LeaveRequestFormState(durationType: type);

  test('a type that takes half days: all three', () {
    expect(
      LeaveFormRules.dayParts(on(LeaveDurationType.fullDay), halfDays),
      LeaveDurationType.values,
    );
  });

  test('a type that takes whole days only, on a full day: none, no card', () {
    expect(
      LeaveFormRules.dayParts(on(LeaveDurationType.fullDay), wholeDays),
      isEmpty,
    );
  });

  test('a type that takes whole days only, with a half day on the form: '
      'that half and a full day, so it can be made a full day', () {
    expect(
      LeaveFormRules.dayParts(on(LeaveDurationType.secondHalf), wholeDays),
      [LeaveDurationType.fullDay, LeaveDurationType.secondHalf],
    );
  });

  test('no type picked yet: none', () {
    expect(
      LeaveFormRules.dayParts(on(LeaveDurationType.fullDay), null),
      isEmpty,
    );
  });
}
