import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

import '../../support/leave_test_doubles.dart';

/// Owner decision 7: an approved leave can be cancelled only before its
/// first leave day; a pending one on any date.
void main() {
  // The sample leave is 18–19 November 2026.
  final dayBefore = DateTime(2026, 11, 17, 23, 59);
  final firstDay = DateTime(2026, 11, 18, 0, 0);
  final after = DateTime(2026, 11, 25);

  test('a pending request can be cancelled on any date', () {
    final request = sampleLeaveRequest();

    expect(request.canCancelInApp(dayBefore), isTrue);
    expect(request.canCancelInApp(firstDay), isTrue);
    expect(request.canCancelInApp(after), isTrue);
    expect(request.hasStartedOn(after), isFalse);
  });

  test('an approved leave can be cancelled up to the day before it starts',
      () {
    final request = sampleLeaveRequest(status: LeaveStatus.approved);

    expect(request.canCancelInApp(dayBefore), isTrue);
    expect(request.hasStartedOn(dayBefore), isFalse);
  });

  test('an approved leave cannot be cancelled from its first day on', () {
    final request = sampleLeaveRequest(status: LeaveStatus.approved);

    expect(request.canCancelInApp(firstDay), isFalse);
    expect(request.hasStartedOn(firstDay), isTrue);
    expect(request.canCancelInApp(after), isFalse);
  });

  test('a rejected or cancelled request cannot be cancelled, and has not '
      '"started"', () {
    for (final status in [LeaveStatus.rejected, LeaveStatus.cancelled]) {
      final request = sampleLeaveRequest(status: status);

      expect(request.canCancelInApp(dayBefore), isFalse, reason: '$status');
      expect(request.hasStartedOn(after), isFalse, reason: '$status');
    }
  });

  test('the first leave day is the first day charged, not the start of the '
      'range', () {
    // Saturday 21 to Tuesday 24 at a company closed at the weekend: the
    // request counts Monday 23 and Tuesday 24.
    final request = sampleLeaveRequest(
      status: LeaveStatus.approved,
      requestDays: [DateTime(2026, 11, 24), DateTime(2026, 11, 23)],
    );

    expect(request.firstLeaveDay, DateTime(2026, 11, 23));
    expect(request.canCancelInApp(DateTime(2026, 11, 22)), isTrue);
    expect(request.canCancelInApp(DateTime(2026, 11, 23)), isFalse);
  });

  test('a request that lists no days goes by its start date', () {
    final request = LeaveRequest(
      id: 'req-1',
      employeeName: 'Noy Phommachanh',
      leaveType: sampleLeaveType(),
      startDate: DateTime(2026, 11, 18),
      endDate: DateTime(2026, 11, 19),
      totalDays: 2,
      status: LeaveStatus.approved,
    );

    expect(request.firstLeaveDay, DateTime(2026, 11, 18));
  });
}
