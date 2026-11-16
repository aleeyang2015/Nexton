import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/data/models/rest_day_model.dart';
import 'package:next_on/features/time_off/domain/entities/company_days_off.dart';

void main() {
  CompanyDaysOff only(RestDayType type, String value) =>
      CompanyDaysOff([RestDayRule(type: type, value: value)]);

  group('weekly', () {
    test('every week on that weekday, and no other day', () {
      final sundays = only(RestDayType.weekly, 'SUN');

      // 2026-11-22 and -29 are Sundays.
      expect(sundays.isDayOff(DateTime(2026, 11, 22)), isTrue);
      expect(sundays.isDayOff(DateTime(2026, 11, 29)), isTrue);
      expect(sundays.isDayOff(DateTime(2026, 11, 21)), isFalse);
      expect(sundays.isDayOff(DateTime(2026, 11, 23)), isFalse);
    });

    test('each code is its own weekday, Monday to Sunday', () {
      const codes = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

      for (var i = 0; i < codes.length; i++) {
        final rule = only(RestDayType.weekly, codes[i]);
        // 2026-11-16 is a Monday.
        for (var offset = 0; offset < 7; offset++) {
          expect(
            rule.isDayOff(DateTime(2026, 11, 16 + offset)),
            offset == i,
            reason: '${codes[i]} on day $offset of the week',
          );
        }
      }
    });

    test('the code is matched whatever its case or padding', () {
      expect(
        only(RestDayType.weekly, ' sun ').isDayOff(DateTime(2026, 11, 22)),
        isTrue,
      );
    });
  });

  group('monthly', () {
    test('every month on that day of the month', () {
      final fifteenth = only(RestDayType.monthly, '15');

      expect(fifteenth.isDayOff(DateTime(2026, 11, 15)), isTrue);
      expect(fifteenth.isDayOff(DateTime(2027, 2, 15)), isTrue);
      expect(fifteenth.isDayOff(DateTime(2026, 11, 14)), isFalse);
    });

    test('a leading 0 is ignored: "08" is the 8th', () {
      final eighth = only(RestDayType.monthly, '08');

      expect(eighth.isDayOff(DateTime(2026, 11, 8)), isTrue);
      expect(eighth.isDayOff(DateTime(2026, 11, 18)), isFalse);
      expect(eighth.isDayOff(DateTime(2026, 11, 28)), isFalse);
    });

    test('the 31st is a day off only in months that have one', () {
      final last = only(RestDayType.monthly, '31');

      expect(last.isDayOff(DateTime(2026, 12, 31)), isTrue);
      // November has 30 days; nothing in it is the 31st.
      for (var day = 1; day <= 30; day++) {
        expect(last.isDayOff(DateTime(2026, 11, day)), isFalse);
      }
    });
  });

  group('yearly', () {
    test('every year on that month and day', () {
      final newYear = only(RestDayType.yearly, '01-01');

      expect(newYear.isDayOff(DateTime(2026, 1, 1)), isTrue);
      expect(newYear.isDayOff(DateTime(2027, 1, 1)), isTrue);
      expect(newYear.isDayOff(DateTime(2026, 1, 2)), isFalse);
      expect(newYear.isDayOff(DateTime(2026, 10, 1)), isFalse);
    });

    test('a leap day is a day off only in a leap year', () {
      final leapDay = only(RestDayType.yearly, '02-29');

      expect(leapDay.isDayOff(DateTime(2028, 2, 29)), isTrue);
      // 2026 and 2027 have no 29 February; the days around it are not it.
      expect(leapDay.isDayOff(DateTime(2026, 2, 28)), isFalse);
      expect(leapDay.isDayOff(DateTime(2026, 3, 1)), isFalse);
      expect(leapDay.isDayOff(DateTime(2027, 2, 28)), isFalse);
    });
  });

  group('custom', () {
    test('that one date only', () {
      final oneOff = only(RestDayType.custom, '2026-12-24');

      expect(oneOff.isDayOff(DateTime(2026, 12, 24)), isTrue);
      expect(oneOff.isDayOff(DateTime(2027, 12, 24)), isFalse);
      expect(oneOff.isDayOff(DateTime(2026, 12, 25)), isFalse);
    });

    test('the time of day does not matter', () {
      expect(
        only(
          RestDayType.custom,
          '2026-12-24',
        ).isDayOff(DateTime(2026, 12, 24, 23, 59)),
        isTrue,
      );
    });
  });

  group('several rules', () {
    const company = CompanyDaysOff([
      RestDayRule(type: RestDayType.weekly, value: 'SUN'),
      RestDayRule(type: RestDayType.monthly, value: '1'),
      RestDayRule(type: RestDayType.yearly, value: '12-02'),
      RestDayRule(type: RestDayType.custom, value: '2026-11-25'),
    ]);

    test('a day is off when any rule says so', () {
      expect(company.isDayOff(DateTime(2026, 11, 22)), isTrue, reason: 'SUN');
      expect(company.isDayOff(DateTime(2026, 12, 1)), isTrue, reason: '1st');
      expect(company.isDayOff(DateTime(2026, 12, 2)), isTrue, reason: '12-02');
      expect(company.isDayOff(DateTime(2026, 11, 25)), isTrue, reason: 'one');
      expect(company.isDayOff(DateTime(2026, 11, 24)), isFalse);
    });

    test('no rules: no day is off', () {
      expect(CompanyDaysOff.none.isDayOff(DateTime(2026, 11, 22)), isFalse);
    });

    test('a value that is not what its kind expects matches nothing', () {
      const odd = CompanyDaysOff([
        RestDayRule(type: RestDayType.weekly, value: 'SUNDAY'),
        RestDayRule(type: RestDayType.monthly, value: 'first'),
        RestDayRule(type: RestDayType.yearly, value: '2026-01-01'),
        RestDayRule(type: RestDayType.custom, value: '01-01'),
      ]);

      for (var day = 1; day <= 31; day++) {
        expect(odd.isDayOff(DateTime(2026, 1, day)), isFalse);
      }
    });
  });

  group('workingDaysBetween', () {
    const sundays = CompanyDaysOff([
      RestDayRule(type: RestDayType.weekly, value: 'SUN'),
    ]);

    test('Friday to Monday at a company closed on Sundays is three days', () {
      expect(
        sundays.workingDaysBetween(
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 23),
        ),
        [
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 21),
          DateTime(2026, 11, 23),
        ],
      );
    });

    test('both ends are included; one day is one day', () {
      expect(
        sundays.workingDaysBetween(
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 20),
        ),
        [DateTime(2026, 11, 20)],
      );
    });

    test('only days off gives none; an end before the start gives none', () {
      expect(
        sundays.workingDaysBetween(
          DateTime(2026, 11, 22),
          DateTime(2026, 11, 22),
        ),
        isEmpty,
      );
      expect(
        sundays.workingDaysBetween(
          DateTime(2026, 11, 23),
          DateTime(2026, 11, 20),
        ),
        isEmpty,
      );
    });

    test('runs across a month and a year end', () {
      expect(
        CompanyDaysOff.none
            .workingDaysBetween(DateTime(2026, 12, 30), DateTime(2027, 1, 2))
            .length,
        4,
      );
    });
  });

  group('firstWorkingDayAfter', () {
    const weekend = CompanyDaysOff([
      RestDayRule(type: RestDayType.weekly, value: 'SAT'),
      RestDayRule(type: RestDayType.weekly, value: 'SUN'),
    ]);

    test('skips the days off: after a Friday it is Monday', () {
      expect(
        weekend.firstWorkingDayAfter(DateTime(2026, 11, 20)),
        DateTime(2026, 11, 23),
      );
    });

    test('is the next day when that is a working day', () {
      expect(
        weekend.firstWorkingDayAfter(DateTime(2026, 11, 17)),
        DateTime(2026, 11, 18),
      );
    });

    test('a company with every weekday off gets the next day, not a hang', () {
      const never = CompanyDaysOff([
        RestDayRule(type: RestDayType.weekly, value: 'MON'),
        RestDayRule(type: RestDayType.weekly, value: 'TUE'),
        RestDayRule(type: RestDayType.weekly, value: 'WED'),
        RestDayRule(type: RestDayType.weekly, value: 'THU'),
        RestDayRule(type: RestDayType.weekly, value: 'FRI'),
        RestDayRule(type: RestDayType.weekly, value: 'SAT'),
        RestDayRule(type: RestDayType.weekly, value: 'SUN'),
      ]);

      expect(
        never.firstWorkingDayAfter(DateTime(2026, 11, 20)),
        DateTime(2026, 11, 21),
      );
    });
  });

  group('RestDayModel.fromJson', () {
    test('reads each kind', () {
      RestDayRule? read(String type, Object value) => RestDayModel.fromJson({
        'id': 'r',
        'name': 'x',
        'type': type,
        'value': value,
      });

      expect(
        read('weekly', 'SUN'),
        const RestDayRule(type: RestDayType.weekly, value: 'SUN'),
      );
      expect(read('monthly', '15')!.type, RestDayType.monthly);
      expect(read('yearly', '01-01')!.type, RestDayType.yearly);
      expect(read('custom', '2026-12-24')!.type, RestDayType.custom);
    });

    test('a monthly value sent as a number is read', () {
      final rule = RestDayModel.fromJson({'type': 'monthly', 'value': 8})!;

      expect(rule.value, '8');
      expect(CompanyDaysOff([rule]).isDayOff(DateTime(2026, 11, 8)), isTrue);
    });

    test('a kind the App does not know, or no value, is left out', () {
      expect(RestDayModel.fromJson({'type': 'lunar', 'value': '1'}), isNull);
      expect(RestDayModel.fromJson({'type': 'weekly'}), isNull);
      expect(RestDayModel.fromJson({'type': 'weekly', 'value': ' '}), isNull);
      expect(RestDayModel.fromJson({'value': 'SUN'}), isNull);
    });
  });
}
