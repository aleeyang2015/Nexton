import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
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

  group('AttendanceCopy.shiftHoursLine', () {
    test('joins the real session labels records/my returned', () {
      const sessions = [
        AttendanceSession(label: '08:00–12:00'),
        AttendanceSession(label: '13:00–17:00'),
      ];

      expect(
        AttendanceCopy.shiftHoursLine(l10n, en, sessions, const []),
        '08:00–12:00 | 13:00–17:00',
      );
    });

    test('skips a session with no label rather than showing a gap', () {
      const sessions = [
        AttendanceSession(label: '08:00–12:00'),
        AttendanceSession(),
      ];

      expect(
        AttendanceCopy.shiftHoursLine(l10n, en, sessions, const []),
        '08:00–12:00',
      );
    });

    test(
      'before the first punch, builds the line from the employee\'s real '
      'shift instead of a canned example',
      () {
        const shiftDetails = [
          ShiftDetail(name: 'Morning', startTime: '08:00:00', endTime: '12:00:00'),
          ShiftDetail(name: 'Afternoon', startTime: '13:00', endTime: '17:00'),
        ];

        expect(
          AttendanceCopy.shiftHoursLine(l10n, en, const [], shiftDetails),
          'Morning: 08:00 - 12:00 | Afternoon: 13:00 - 17:00',
        );
      },
    );

    test(
      'falls back to the placeholder when there are no sessions and no '
      'shift on file either',
      () {
        expect(
          AttendanceCopy.shiftHoursLine(l10n, en, const [], const []),
          l10n.shiftHoursPlaceholder,
        );
      },
    );
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
}
