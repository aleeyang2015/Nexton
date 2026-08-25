import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('AttendanceCopy.statusBadge', () {
    test('reads REG - Regular Time from an on-time day', () {
      const day = AttendanceDay(
        sessions: [AttendanceSession(isLate: false)],
      );

      expect(AttendanceCopy.statusBadge(l10n, day).label, 'REG - Regular Time');
    });

    test('reads Late when any session today was late', () {
      const day = AttendanceDay(
        sessions: [
          AttendanceSession(isLate: false),
          AttendanceSession(isLate: true),
        ],
      );

      expect(AttendanceCopy.statusBadge(l10n, day).label, 'Late');
    });

    test('a day with no sessions yet defaults to Regular Time', () {
      expect(
        AttendanceCopy.statusBadge(l10n, AttendanceDay.empty).label,
        'REG - Regular Time',
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
        AttendanceCopy.shiftHoursLine(l10n, sessions),
        '08:00–12:00 | 13:00–17:00',
      );
    });

    test('skips a session with no label rather than showing a gap', () {
      const sessions = [
        AttendanceSession(label: '08:00–12:00'),
        AttendanceSession(),
      ];

      expect(AttendanceCopy.shiftHoursLine(l10n, sessions), '08:00–12:00');
    });

    test('falls back to the placeholder before the day has any sessions', () {
      expect(
        AttendanceCopy.shiftHoursLine(l10n, const []),
        l10n.shiftHoursPlaceholder,
      );
    });
  });
}
