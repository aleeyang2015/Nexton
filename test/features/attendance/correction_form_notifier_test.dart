import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_form_notifier.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail_weekly.dart';
import 'package:next_on/features/profile/profile_providers.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/profile_test_doubles.dart';

/// The "forgot to scan" form, filled from a history day (#44).
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // A day a week back, inside the 30 days.
  final weekAgo = DateTime(today.year, today.month, today.day - 7);
  final weekdayCode = const [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ][weekAgo.weekday - 1];

  final morning = ShiftDetail(
    id: 'p-am',
    startTime: '08:00',
    endTime: '12:00',
    // That weekday starts late.
    weeklys: [ShiftDetailWeekly(weeklyDay: weekdayCode, startTime: '09:00')],
  );
  const afternoon = ShiftDetail(
    id: 'p-pm',
    startTime: '13:00',
    endTime: '17:00',
  );

  late FakeAttendanceRepository attendance;
  late FakeProfileRepository profiles;
  late ProviderContainer container;

  ProviderContainer make({List<ShiftDetail>? parts}) {
    profiles = FakeProfileRepository()
      ..profile = Result.success(
        EmployeeProfile(
          id: 'e1',
          fullName: 'Noy',
          shiftDetails: parts ?? [morning, afternoon],
        ),
      );
    attendance = FakeAttendanceRepository();
    final c = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(attendance),
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    c.listen(timeCorrectionFormNotifierProvider, (_, _) {});
    return c;
  }

  tearDown(() => container.dispose());

  TimeCorrectionFormNotifier form() =>
      container.read(timeCorrectionFormNotifierProvider.notifier);

  Future<void> settle() => pumpEventQueue();

  test(
    'from a history session: its day, its part, that weekday\'s times',
    () async {
      container = make();
      await settle();

      form().prefill(date: weekAgo, partId: 'p-am');
      await settle();

      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(state.date, weekAgo);
      expect(state.shiftDetail?.id, 'p-am');
      expect(state.clockIn, const TimeOfDay(hour: 9, minute: 0));
      expect(state.clockOut, const TimeOfDay(hour: 12, minute: 0));
    },
  );

  test(
    'the profile loading after the prefill: the asked part still wins',
    () async {
      container = make();
      form().prefill(date: weekAgo, partId: 'p-pm');
      await settle();

      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail?.id,
        'p-pm',
      );
    },
  );

  test(
    'a part the profile no longer has: the history session\'s own',
    () async {
      container = make();
      await settle();
      const old = ShiftDetail(
        id: 'p-old',
        startTime: '07:00',
        endTime: '11:00',
      );

      form().prefill(date: weekAgo, partId: 'p-old', sessionPart: old);

      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(state.shiftDetail, old);
      expect(state.clockIn, const TimeOfDay(hour: 7, minute: 0));
    },
  );

  test('no date given: today and the profile\'s first part', () async {
    container = make();
    await settle();

    final state = container.read(timeCorrectionFormNotifierProvider);
    expect(state.date, today);
    expect(state.shiftDetail?.id, 'p-am');
  });

  test('a date outside the 30 days is not taken', () async {
    container = make();
    await settle();

    form().prefill(date: today.subtract(const Duration(days: 45)));

    expect(container.read(timeCorrectionFormNotifierProvider).date, today);
  });

  test('no part at all: nothing is sent', () async {
    container = make(parts: const []);
    await settle();
    form().setReason('Forgot');

    expect(await form().submit(), isFalse);
    expect(attendance.timeCorrectionRequests, isEmpty);
    expect(
      container
          .read(timeCorrectionFormNotifierProvider)
          .errorFor(TimeCorrectionFields.shift),
      isNotNull,
    );
  });

  test('a double tap on Send sends once', () async {
    container = make();
    await settle();
    form().setReason('Forgot');
    final slow = Completer<void>();
    attendance.holdTimeCorrection = slow;

    final first = form().submit();
    await form().submit();
    slow.complete();
    await first;

    expect(attendance.timeCorrectionRequests, hasLength(1));
  });
}
