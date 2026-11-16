import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('dayCount', () {
    test('a whole number of days is written whole', () {
      expect(LeaveCopy.dayCount(3), '3');
      expect(LeaveCopy.dayCount(0), '0');
      expect(LeaveCopy.dayCount(15), '15');
    });

    test('a half is written with one decimal, never rounded away', () {
      expect(LeaveCopy.dayCount(7.5), '7.5');
      expect(LeaveCopy.dayCount(0.5), '0.5');
      expect(LeaveCopy.dayCount(2.5), '2.5');
    });

    test('a count with two decimals keeps them; nothing is rounded to a '
        'different number', () {
      expect(LeaveCopy.dayCount(7.25), '7.25');
      expect(LeaveCopy.dayCount(7.05), '7.05');
      expect(LeaveCopy.dayCount(2.96), '2.96');
      // Trailing zeros are dropped, not the digits before them.
      expect(LeaveCopy.dayCount(10), '10');
      expect(LeaveCopy.dayCount(10.5), '10.5');
      expect(LeaveCopy.dayCount(100), '100');
    });

    test('a negative balance is written as it is', () {
      expect(LeaveCopy.dayCount(-1), '-1');
      expect(LeaveCopy.dayCount(-0.5), '-0.5');
    });

    test('something that is not a number is a dash, never a crash', () {
      expect(LeaveCopy.dayCount(double.nan), '-');
      expect(LeaveCopy.dayCount(double.infinity), '-');
      expect(LeaveCopy.dayCount(double.negativeInfinity), '-');
    });

    test('Latin digits, whatever the language', () {
      expect(LeaveCopy.dayCount(12.5), matches(r'^[0-9.]+$'));
    });
  });

  group('daysLabel', () {
    test('7.5 days left reads "7.5", not "8"', () {
      expect(LeaveCopy.daysLabel(en, 7.5), '7.5 days');
      expect(LeaveCopy.daysLabel(lo, 7.5), '7.5 ວັນ');
    });

    test('3 days reads "3"', () {
      expect(LeaveCopy.daysLabel(en, 3), '3 days');
      expect(LeaveCopy.daysLabel(lo, 3), '3 ວັນ');
    });

    test('exactly half a day keeps its own wording', () {
      expect(LeaveCopy.daysLabel(en, 0.5), en.leaveHalfDayLabel);
      expect(LeaveCopy.daysLabel(lo, 0.5), lo.leaveHalfDayLabel);
    });

    test('the "used" line and the max-days hint take the same count', () {
      expect(
        en.leaveBalanceUsedLabel(LeaveCopy.dayCount(4.5)),
        'Used 4.5 days',
      );
      expect(
        en.leaveMaxDaysHint(LeaveCopy.dayCount(2.5)),
        contains('2.5 days'),
      );
      expect(en.leaveMaxDaysHint(LeaveCopy.dayCount(5)), contains('5 days'));
    });

    test('the date line carries the same count', () {
      expect(
        LeaveCopy.dateLine(
          en,
          startDate: DateTime(2026, 11, 18),
          endDate: DateTime(2026, 11, 20),
          totalDays: 2.5,
        ),
        endsWith('2.5 days'),
      );
    });
  });

  group('leaveTypeLabel', () {
    // A request's own leave type: id, name, code and colour, no Lao name.
    const onRequest = LeaveType(
      id: 'lt-annual',
      code: 'annual',
      name: 'Annual Leave',
    );
    final loaded = [
      sampleLeaveType(id: 'lt-sick', name: 'Sick Leave', nameLo: 'ລາປ່ວຍ'),
      sampleLeaveType(),
    ];

    test('in Lao, the name is looked up by id in the loaded types', () {
      expect(
        LeaveCopy.leaveTypeLabel(lo, onRequest, types: loaded),
        'ລາພັກປະຈຳປີ',
      );
    });

    test('falls back to the request\'s own name when the list has not '
        'loaded, or no longer has that type', () {
      expect(LeaveCopy.leaveTypeLabel(lo, onRequest), 'Annual Leave');
      expect(
        LeaveCopy.leaveTypeLabel(
          lo,
          onRequest,
          types: [sampleLeaveType(id: 'lt-other', nameLo: 'ອື່ນໆ')],
        ),
        'Annual Leave',
      );
    });

    test('falls back when the loaded type has no Lao name either', () {
      expect(
        LeaveCopy.leaveTypeLabel(
          lo,
          onRequest,
          types: [sampleLeaveType(nameLo: null)],
        ),
        'Annual Leave',
      );
    });

    test('a type that carries its own Lao name uses it', () {
      expect(LeaveCopy.leaveTypeLabel(lo, sampleLeaveType()), 'ລາພັກປະຈຳປີ');
    });

    test('in English the name is the default one, list or no list', () {
      expect(
        LeaveCopy.leaveTypeLabel(en, onRequest, types: loaded),
        'Annual Leave',
      );
      expect(LeaveCopy.leaveTypeLabel(en, sampleLeaveType()), 'Annual Leave');
    });
  });
}
