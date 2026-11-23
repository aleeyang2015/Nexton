import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_form_rules.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';

import '../../support/leave_test_doubles.dart';

/// A company day off picked as a separate day while the days off were not
/// known is caught once they are (#128): the server would charge it.
void main() {
  // 2026-11-20 is a Friday, the 22nd a Sunday, the 29th the next Sunday.
  final friday = DateTime(2026, 11, 20);
  final sunday = DateTime(2026, 11, 22);
  final nextSunday = DateTime(2026, 11, 29);

  LeaveRequestFormState separate(
    List<DateTime> dates, {
    LeaveDurationType duration = LeaveDurationType.fullDay,
    String? editingId,
    List<DateTime> originalDates = const [],
    bool daysOffKnown = true,
  }) => LeaveRequestFormState(
    editingRequestId: editingId,
    leaveTypeId: 'lt-annual',
    mode: LeaveDaysMode.separateDays,
    dates: dates,
    durationType: duration,
    daysOff: daysOffKnown ? sundaysOff : null,
    originalDates: originalDates,
  );

  LeaveFormBlock? block(LeaveRequestFormState state) => LeaveFormRules.block(
    state: state,
    type: sampleLeaveType(),
    remainingByYear: const {2026: 10},
  );

  test('a separate day that is a day off blocks, and is named', () {
    final state = separate([friday, sunday]);

    expect(LeaveFormRules.pickedDayOff(state), sunday);
    expect(block(state), LeaveFormBlock.dayOffPicked);
  });

  test('the first day off picked is the one named', () {
    expect(
      LeaveFormRules.pickedDayOff(separate([nextSunday, friday, sunday])),
      sunday,
    );
  });

  test('working days only: not blocked', () {
    final state = separate([friday]);

    expect(LeaveFormRules.pickedDayOff(state), isNull);
    expect(block(state), isNull);
  });

  test('a half day on a day off blocks the same way', () {
    final state = separate([sunday], duration: LeaveDurationType.firstHalf);

    expect(block(state), LeaveFormBlock.dayOffPicked);
  });

  test('the days off not known: nothing is blocked on what cannot be '
      'checked', () {
    final state = separate([sunday], daysOffKnown: false);

    expect(LeaveFormRules.pickedDayOff(state), isNull);
    expect(block(state), isNull);
  });

  test('a range is not this check: the server counts its working days', () {
    final state = LeaveRequestFormState(
      leaveTypeId: 'lt-annual',
      rangeStart: friday,
      rangeEnd: DateTime(2026, 11, 23),
      daysOff: sundaysOff,
    );

    expect(LeaveFormRules.pickedDayOff(state), isNull);
  });

  test('an edit keeps a day off it already had (HR changed the calendar '
      'since): a reason-only edit still saves', () {
    final state = separate(
      [friday, sunday],
      editingId: 'req-7',
      originalDates: [friday, sunday],
    );

    expect(LeaveFormRules.pickedDayOff(state), isNull);
    expect(block(state), isNull);
  });

  test('an edit that adds a day off is blocked on the one added', () {
    final state = separate(
      [friday, sunday, nextSunday],
      editingId: 'req-7',
      originalDates: [friday, sunday],
    );

    expect(LeaveFormRules.pickedDayOff(state), nextSunday);
    expect(block(state), LeaveFormBlock.dayOffPicked);
  });
}
