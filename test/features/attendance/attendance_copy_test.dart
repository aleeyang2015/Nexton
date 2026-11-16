import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_copy.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const en = Locale('en');
  const lo = Locale('lo');

  group('AttendanceCopy.statusBadge', () {
    test('falls back to Regular Time when no shift name is on file', () {
      expect(AttendanceCopy.statusBadge(l10n).label, 'REG - Regular Time');
    });

    test('shows the employee\'s real shift name in place of Regular Time', () {
      expect(
        AttendanceCopy.statusBadge(l10n, shiftName: 'Regular Shift').label,
        'Regular Shift',
      );
    });
  });

  group('AttendanceCopy.shiftDetailName', () {
    const detail = ShiftDetail(name: 'Morning', nameLo: 'ກະເຊົ້າ');

    test('prefers name_lo under the Lao locale', () {
      expect(AttendanceCopy.shiftDetailName(lo, detail), 'ກະເຊົ້າ');
    });

    test('prefers name under any other locale', () {
      expect(AttendanceCopy.shiftDetailName(en, detail), 'Morning');
    });

    test('falls back to whichever name the backend actually sent', () {
      const nameOnly = ShiftDetail(name: 'Morning');
      const nameLoOnly = ShiftDetail(nameLo: 'ກະເຊົ້າ');

      expect(AttendanceCopy.shiftDetailName(lo, nameOnly), 'Morning');
      expect(AttendanceCopy.shiftDetailName(en, nameLoOnly), 'ກະເຊົ້າ');
    });
  });

  group('AttendanceCopy.employeeShiftName', () {
    test('prefers name_lo under the Lao locale', () {
      expect(
        AttendanceCopy.employeeShiftName(lo, 'Regular Shift', 'ກະປົກກະຕິ'),
        'ກະປົກກະຕິ',
      );
    });

    test('prefers name under any other locale', () {
      expect(
        AttendanceCopy.employeeShiftName(en, 'Regular Shift', 'ກະປົກກະຕິ'),
        'Regular Shift',
      );
    });

    test('is null when the employee has no shift assigned', () {
      expect(AttendanceCopy.employeeShiftName(en, null, null), isNull);
    });
  });

  group('AttendanceCopy.rule', () {
    final lao = lookupAppLocalizations(lo);
    const serverEnglish = 'Clock-in rejected by the server, in English.';

    String text(
      AppLocalizations l10n,
      AttendanceRule rule, [
      PunchBlockDetails details = PunchBlockDetails.empty,
    ]) => AttendanceCopy.rule(
      l10n,
      PunchBlocked(rule: rule, message: serverEnglish, details: details),
    );

    test('every rule gives the App\'s Lao text, even though the server sent '
        'a message', () {
      for (final rule in AttendanceRule.values) {
        final shown = text(lao, rule);

        expect(shown, isNot(serverEnglish), reason: '$rule');
        expect(shown, isNotEmpty, reason: '$rule');
        // Lao script, not English copy that slipped through.
        expect(
          RegExp(r'[\u0E80-\u0EFF]').hasMatch(shown),
          isTrue,
          reason: '$rule shows "$shown"',
        );
      }
    });

    test('every rule gives English text under the English locale', () {
      for (final rule in AttendanceRule.values) {
        final shown = text(l10n, rule);

        expect(shown, isNot(serverEnglish), reason: '$rule');
        expect(
          RegExp(r'[\u0E80-\u0EFF]').hasMatch(shown),
          isFalse,
          reason: '$rule shows "$shown"',
        );
      }
    });

    test('too early names when clock-in opens, and falls back without it', () {
      expect(
        text(
          lao,
          AttendanceRule.tooEarlyCheckin,
          const PunchBlockDetails(clockInOpens: '07:00'),
        ),
        contains('07:00'),
      );
      expect(
        text(lao, AttendanceRule.tooEarlyCheckin),
        lao.ruleTooEarlyCheckin,
      );
    });

    test('clock-out before clock-in names the clock-in time, and falls back '
        'without it', () {
      expect(
        text(
          lao,
          AttendanceRule.clockOutBeforeClockIn,
          const PunchBlockDetails(clockIn: '08:05'),
        ),
        'ທ່ານລົງເວລາເຂົ້າຕອນ 08:05. ລົງເວລາອອກກ່ອນນັ້ນບໍ່ໄດ້.',
      );
      expect(
        text(
          l10n,
          AttendanceRule.clockOutBeforeClockIn,
          const PunchBlockDetails(clockIn: '08:05'),
        ),
        'You clocked in at 08:05. You can\'t clock out before that.',
      );
      expect(
        text(lao, AttendanceRule.clockOutBeforeClockIn),
        lao.ruleClockOutBeforeClockIn,
      );
    });

    test('a closed clock-out window names when it closed, and falls back '
        'without it', () {
      expect(
        text(
          lao,
          AttendanceRule.afterCheckoutWindow,
          const PunchBlockDetails(latestCheckout: '18:30'),
        ),
        'ເລີຍເວລາລົງເວລາອອກແລ້ວ (ເປີດຮອດ 18:30).',
      );
      expect(
        text(
          l10n,
          AttendanceRule.afterCheckoutWindow,
          const PunchBlockDetails(latestCheckout: '18:30'),
        ),
        'The clock-out window has closed (it was open until 18:30).',
      );
      expect(
        text(lao, AttendanceRule.afterCheckoutWindow),
        lao.ruleAfterCheckoutWindow,
      );
    });

    test('closed check-in names when the last shift ended, and falls back '
        'without it', () {
      expect(
        text(
          lao,
          AttendanceRule.outsideShiftHours,
          const PunchBlockDetails(lastShiftEnd: '17:30'),
        ),
        'ໝົດເວລາລົງເວລາເຂົ້າຂອງມື້ນີ້ແລ້ວ (ກະສຸດທ້າຍຈົບ 17:30).',
      );
      expect(
        text(
          l10n,
          AttendanceRule.outsideShiftHours,
          const PunchBlockDetails(lastShiftEnd: '17:30'),
        ),
        'Check-in has closed for today (the last shift ended at 17:30).',
      );
      expect(
        text(lao, AttendanceRule.outsideShiftHours),
        lao.ruleOutsideShiftHours,
      );
    });

    test('OT changed asks to try again', () {
      expect(
        text(lao, AttendanceRule.otChanged),
        'ໂອທີຂອງທ່ານຫາກໍ່ປ່ຽນ. ກະລຸນາລອງໃໝ່.',
      );
      expect(
        text(l10n, AttendanceRule.otChanged),
        'Your OT just changed. Please try again.',
      );
    });

    test('the wordings that name a time are in the user\'s language too', () {
      const details = PunchBlockDetails(
        clockInOpens: '07:00',
        clockIn: '08:05',
        latestCheckout: '18:30',
        lastShiftEnd: '17:30',
      );
      const timed = {
        AttendanceRule.tooEarlyCheckin: '07:00',
        AttendanceRule.clockOutBeforeClockIn: '08:05',
        AttendanceRule.afterCheckoutWindow: '18:30',
        AttendanceRule.outsideShiftHours: '17:30',
      };

      for (final MapEntry(key: rule, value: time) in timed.entries) {
        final inLao = text(lao, rule, details);
        final inEnglish = text(l10n, rule, details);

        expect(inLao, contains(time), reason: '$rule');
        expect(RegExp(r'[\u0E80-\u0EFF]').hasMatch(inLao), isTrue);
        expect(inEnglish, contains(time), reason: '$rule');
        expect(RegExp(r'[\u0E80-\u0EFF]').hasMatch(inEnglish), isFalse);
        // And not the same sentence as the one that names no time.
        expect(inLao, isNot(text(lao, rule)), reason: '$rule');
      }
    });

    test('an empty detail is treated as missing, not shown as a blank', () {
      expect(
        text(
          lao,
          AttendanceRule.afterCheckoutWindow,
          const PunchBlockDetails(latestCheckout: ''),
        ),
        lao.ruleAfterCheckoutWindow,
      );
    });
  });

  group('AttendanceCopy.detailTime', () {
    test('a wall-clock time is shown as HH:MM, without seconds', () {
      expect(AttendanceCopy.detailTime('17:30'), '17:30');
      expect(AttendanceCopy.detailTime('17:30:00'), '17:30');
      expect(AttendanceCopy.detailTime('7:05'), '07:05');
      expect(AttendanceCopy.detailTime(' 07:00 '), '07:00');
    });

    test('a date-time stamp becomes the local HH:mm', () {
      final stamp = DateTime(2026, 11, 16, 18, 30).toUtc().toIso8601String();

      expect(AttendanceCopy.detailTime(stamp), '18:30');
    });

    test('nothing to show reads as missing, so the plain wording is used', () {
      expect(AttendanceCopy.detailTime(null), isNull);
      expect(AttendanceCopy.detailTime(''), isNull);
      expect(AttendanceCopy.detailTime('   '), isNull);
    });

    test('a value that is not a time is left out, not shown as 00:00', () {
      // The zero date a missing Go time serialises to.
      expect(AttendanceCopy.detailTime('0001-01-01T00:00:00Z'), isNull);
      // `DateTime.tryParse` would read these as dates.
      expect(AttendanceCopy.detailTime('20261116'), isNull);
      expect(AttendanceCopy.detailTime('1794812400'), isNull);
      expect(AttendanceCopy.detailTime('730'), isNull);
    });

    test('other text passes through untouched', () {
      expect(AttendanceCopy.detailTime('13:30–17:30'), '13:30–17:30');
    });
  });
}
