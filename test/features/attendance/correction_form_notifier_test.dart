import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/date_range.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_attachment_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_form_notifier.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail_weekly.dart';
import 'package:next_on/features/profile/presentation/providers/profile_notifier.dart';
import 'package:next_on/features/profile/profile_providers.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/upload_test_doubles.dart';

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
        uploadRepositoryProvider.overrideWithValue(FakeUploads()),
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

  test('the uploaded photo goes with the request; a removed one does not '
      '(#73)', () async {
    container = make();
    container.listen(timeCorrectionAttachmentNotifierProvider, (_, _) {});
    await settle();
    form().setReason('Forgot');
    final photo = container.read(
      timeCorrectionAttachmentNotifierProvider.notifier,
    );

    await photo.upload(
      const LocalFile(path: '/no/such/sheet.jpg', name: 'sheet.jpg'),
    );
    expect(await form().submit(), isTrue);
    expect(
      attendance.timeCorrectionRequests.last.attachment?.url,
      'https://files.nexton.work/uploads/sheet.jpg',
    );

    photo.clear();
    expect(await form().submit(), isTrue);
    expect(attendance.timeCorrectionRequests.last.attachment, isNull);
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

  group('review fixes', () {
    // Three days back: another weekday than today's, with its own row.
    final otherDay = DateTime(today.year, today.month, today.day - 3);
    final otherCode = const [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ][otherDay.weekday - 1];
    final lateOnOtherDay = ShiftDetail(
      id: 'p-x',
      startTime: '08:00',
      endTime: '12:00',
      weeklys: [ShiftDetailWeekly(weeklyDay: otherCode, startTime: '10:00')],
    );

    test(
      'a date-only prefill: the times are that weekday\'s, not today\'s',
      () async {
        container = make(parts: [lateOnOtherDay]);
        await settle();
        expect(
          container.read(timeCorrectionFormNotifierProvider).clockIn,
          const TimeOfDay(hour: 8, minute: 0),
        );

        form().prefill(date: otherDay);

        final state = container.read(timeCorrectionFormNotifierProvider);
        expect(state.date, otherDay);
        expect(state.clockIn, const TimeOfDay(hour: 10, minute: 0));
      },
    );

    test('changing the date resets the times to that weekday\'s', () async {
      container = make(parts: [lateOnOtherDay]);
      await settle();

      form().setDate(otherDay);

      expect(
        container.read(timeCorrectionFormNotifierProvider).clockIn,
        const TimeOfDay(hour: 10, minute: 0),
      );
    });

    test('a session\'s bare copy of the part gives way to the profile\'s full '
        'one when the profile lands', () async {
      container = make();
      // Prefilled before the profile has loaded.
      const bare = ShiftDetail(
        id: 'p-am',
        startTime: '08:00',
        endTime: '12:00',
      );
      form().prefill(date: weekAgo, partId: 'p-am', sessionPart: bare);
      await settle();

      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(state.shiftDetail, morning);
      expect(state.clockIn, const TimeOfDay(hour: 9, minute: 0));
    });

    test('a profile refresh does not undo the user\'s own pick', () async {
      container = make();
      await settle();
      form().prefill(date: weekAgo, partId: 'p-am');
      form().selectShiftDetail(afternoon);
      form().setClockOut(const TimeOfDay(hour: 17, minute: 5));

      container.invalidate(profileNotifierProvider);
      await settle();

      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(state.shiftDetail?.id, 'p-pm');
      expect(state.clockOut, const TimeOfDay(hour: 17, minute: 5));
    });

    test(
      'the session\'s own part stays offered after another is picked',
      () async {
        container = make();
        await settle();
        const old = ShiftDetail(
          id: 'p-old',
          startTime: '07:00',
          endTime: '11:00',
        );
        form().prefill(date: weekAgo, partId: 'p-old', sessionPart: old);
        form().selectShiftDetail(afternoon);

        expect(form().offeredParts([morning, afternoon]).map((p) => p.id), [
          'p-old',
          'p-am',
          'p-pm',
        ]);
      },
    );
  });

  group('the parts offered are the picked day\'s own (#44)', () {
    const old = AttendanceSession(
      partId: 'p-old',
      partName: 'Early',
      partStartTime: '07:00',
      partEndTime: '11:00',
    );

    /// What the history holds for [weekAgo]: its sessions' parts.
    void historyHas(List<AttendanceSession> sessions) {
      attendance.monthRecords = Result.success([
        AttendanceDay(date: weekAgo, sessions: sessions),
      ]);
    }

    List<String?> offeredIds() => [
      for (final part in form().offeredParts([morning, afternoon])) part.id,
    ];

    test('opened from the menu, then a date picked: that day\'s part is '
        'offered first and chosen, ahead of the profile\'s', () async {
      container = make();
      historyHas([old]);
      await settle();

      form().setDate(weekAgo);
      await settle();

      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(offeredIds(), ['p-old', 'p-am', 'p-pm']);
      expect(state.shiftDetail?.id, 'p-old');
      expect(state.clockIn, const TimeOfDay(hour: 7, minute: 0));
      expect(state.clockOut, const TimeOfDay(hour: 11, minute: 0));
    });

    test('a part the day and the profile share is the profile\'s full copy: '
        'that weekday\'s times', () async {
      container = make();
      historyHas([
        const AttendanceSession(partId: 'p-pm'),
        const AttendanceSession(partId: 'p-am'),
        // Two sessions on one part: offered once.
        const AttendanceSession(partId: 'p-am'),
      ]);
      await settle();

      form().setDate(weekAgo);
      await settle();

      final state = container.read(timeCorrectionFormNotifierProvider);
      // In the day's order.
      expect(form().offeredParts([morning, afternoon]), [afternoon, morning]);
      // The part already chosen is one of them: kept.
      expect(state.shiftDetail, morning);
      expect(state.clockIn, const TimeOfDay(hour: 9, minute: 0));
    });

    test('a day with no sessions, or sessions outside any part: the '
        'profile\'s parts', () async {
      container = make();
      historyHas([const AttendanceSession()]);
      await settle();

      form().setDate(weekAgo);
      await settle();

      expect(offeredIds(), ['p-am', 'p-pm']);
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail?.id,
        'p-am',
      );
    });

    test('moving from a day with its own part to a day without: back to the '
        'profile\'s first part', () async {
      container = make();
      historyHas([old]);
      await settle();
      form().setDate(weekAgo);
      await settle();

      final dayAfter = DateTime(weekAgo.year, weekAgo.month, weekAgo.day + 1);
      form().setDate(dayAfter);
      await settle();

      expect(offeredIds(), ['p-am', 'p-pm']);
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail?.id,
        'p-am',
      );
    });

    test('the history cannot be read: the profile\'s parts, and the form '
        'still works', () async {
      container = make();
      attendance.monthRecords = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await settle();

      form().setDate(weekAgo);
      await settle();

      expect(offeredIds(), ['p-am', 'p-pm']);
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail?.id,
        'p-am',
      );
    });

    test('the user\'s own pick among the day\'s parts is kept', () async {
      container = make();
      historyHas([
        const AttendanceSession(partId: 'p-am'),
        const AttendanceSession(partId: 'p-pm'),
      ]);
      await settle();
      form().setDate(weekAgo);
      await settle();

      form().selectShiftDetail(afternoon);
      await settle();

      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('from a history row: the asked part stays, and the day\'s parts are '
        'the ones offered', () async {
      container = make();
      historyHas([old, const AttendanceSession(partId: 'p-pm')]);
      await settle();

      form().prefill(date: weekAgo, partId: 'p-pm');
      await settle();

      expect(offeredIds(), ['p-old', 'p-pm', 'p-am']);
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('one of the day\'s two parts was scanned: the other, never '
        'scanned, can still be picked', () async {
      container = make();
      historyHas([const AttendanceSession(partId: 'p-am')]);
      await settle();

      form().setDate(weekAgo);
      await settle();

      expect(offeredIds(), ['p-am', 'p-pm']);
      form().selectShiftDetail(afternoon);
      await settle();
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('a link to a part the day has no session on: the asked part stays, '
        'whichever of the profile and the history answers first', () async {
      // The profile first, then the history.
      container = make();
      historyHas([const AttendanceSession(partId: 'p-am')]);
      await settle();
      form().prefill(date: weekAgo, partId: 'p-pm');
      await settle();
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
      container.dispose();

      // Asked before either has answered.
      container = make();
      historyHas([const AttendanceSession(partId: 'p-am')]);
      form().prefill(date: weekAgo, partId: 'p-pm');
      await settle();
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('from a history row on a part the profile no longer has, then '
        'another day picked: that day\'s own part, not the old one', () async {
      container = make();
      const oldPart = ShiftDetail(
        id: 'p-old',
        startTime: '07:00',
        endTime: '11:00',
      );
      final dayAfter = DateTime(weekAgo.year, weekAgo.month, weekAgo.day + 1);
      attendance.monthRecords = Result.success([
        AttendanceDay(date: weekAgo, sessions: const [old]),
        AttendanceDay(
          date: dayAfter,
          sessions: const [AttendanceSession(partId: 'p-pm')],
        ),
      ]);
      await settle();
      form().prefill(date: weekAgo, partId: 'p-old', sessionPart: oldPart);
      await settle();
      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail?.id,
        'p-old',
      );

      form().setDate(dayAfter);
      await settle();

      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('a link with a part id nobody knows: the day\'s own part is '
        'chosen', () async {
      container = make();
      historyHas([const AttendanceSession(partId: 'p-pm')]);
      await settle();

      form().prefill(date: weekAgo, partId: 'p-gone');
      await settle();

      expect(
        container.read(timeCorrectionFormNotifierProvider).shiftDetail,
        afternoon,
      );
    });

    test('the history answering late does not undo the user\'s own part or '
        'the times they set', () async {
      container = make();
      // The history names the morning part for that day, but answers only
      // after the user has picked the afternoon and set a time.
      historyHas([const AttendanceSession(partId: 'p-am')]);
      form()
        ..setDate(weekAgo)
        ..selectShiftDetail(afternoon)
        ..setClockIn(const TimeOfDay(hour: 13, minute: 7));
      await settle();

      expect(offeredIds(), ['p-am', 'p-pm']);
      final state = container.read(timeCorrectionFormNotifierProvider);
      expect(state.shiftDetail, afternoon);
      expect(state.clockIn, const TimeOfDay(hour: 13, minute: 7));
    });

    test('a month is read once, however many of its days are picked',
        () async {
      container = make();
      await settle();
      final before = attendance.recordsRanges.length;

      form().setDate(today);
      await settle();
      form().setDate(today);
      await settle();

      expect(before, 1);
      expect(attendance.recordsRanges.length, 1);
      expect(attendance.recordsRanges.single, DateRange.month(today));
    });
  });
}
