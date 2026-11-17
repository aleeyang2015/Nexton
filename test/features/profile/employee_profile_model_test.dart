import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/profile/data/models/employee_profile_model.dart';

void main() {
  group('EmployeeProfileModel.fromJson', () {
    test('reads shift.name/name_lo — the shift\'s own name', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'Somphone Vilaysone',
        'shift': {'id': 'shift-1', 'name': 'Regular Shift', 'name_lo': 'ກະປົກກະຕິ'},
      });

      expect(profile.shiftName, 'Regular Shift');
      expect(profile.shiftNameLo, 'ກະປົກກະຕິ');
    });

    test('shift name is null when the employee has no shift assigned', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'No Shift',
      });

      expect(profile.shiftName, isNull);
      expect(profile.shiftNameLo, isNull);
    });

    test('reads shift.shift_details into ShiftDetail entries in order', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'Somphone Vilaysone',
        'shift': {
          'id': 'shift-1',
          'shift_details': [
            {
              'name': 'Morning',
              'name_lo': 'ກະເຊົ້າ',
              'start_time': '08:00:00',
              'end_time': '12:00:00',
            },
            {
              'name': 'Afternoon',
              'name_lo': 'ກະແລງ',
              'start_time': '13:00:00',
              'end_time': '17:00:00',
            },
          ],
        },
      });

      expect(profile.shiftDetails, hasLength(2));

      final morning = profile.shiftDetails[0];
      expect(morning.name, 'Morning');
      expect(morning.nameLo, 'ກະເຊົ້າ');
      expect(morning.startTime, '08:00:00');
      expect(morning.endTime, '12:00:00');

      final afternoon = profile.shiftDetails[1];
      expect(afternoon.name, 'Afternoon');
      expect(afternoon.nameLo, 'ກະແລງ');
    });

    test('is empty when the employee has no shift assigned', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'No Shift',
      });

      expect(profile.shiftDetails, isEmpty);
    });

    test('is empty when shift has no shift_details array', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'Bare Shift',
        'shift': {'id': 'shift-1'},
      });

      expect(profile.shiftDetails, isEmpty);
    });
  });

  group('shift_details[]: the part id, ends_next_day and weeklys', () {
    Map<String, dynamic> profileWith(Map<String, dynamic> part) => {
      'id': '1',
      'full_name': 'Mai',
      'shift': {
        'id': 'shift-1',
        'shift_details': [part],
      },
    };

    test('reads id and ends_next_day', () {
      final night = EmployeeProfileModel.fromJson(
        profileWith({
          'id': 'part-night',
          'name': 'Night',
          'start_time': '22:00',
          'end_time': '06:00',
          'ends_next_day': true,
          'weeklys': <dynamic>[],
        }),
      ).shiftDetails.single;

      expect(night.id, 'part-night');
      expect(night.endsNextDay, isTrue);
    });

    test('ends_next_day is false when missing or not a bool', () {
      final missing = EmployeeProfileModel.fromJson(
        profileWith({'id': 'p', 'start_time': '08:00', 'end_time': '17:00'}),
      ).shiftDetails.single;
      final odd = EmployeeProfileModel.fromJson(
        profileWith({'id': 'p', 'ends_next_day': 'yes'}),
      ).shiftDetails.single;

      expect(missing.endsNextDay, isFalse);
      expect(odd.endsNextDay, isFalse);
    });

    test('weeklys are parsed in the order sent', () {
      final part = EmployeeProfileModel.fromJson(
        profileWith({
          'id': 'p',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
          'weeklys': [
            {
              'weekly_day': 'SAT',
              'start_time': '08:00:00',
              'end_time': '12:00:00',
              'late_grace_minutes': 5,
            },
            {'weekly_day': 'MON', 'start_time': '09:00', 'end_time': '18:00'},
          ],
        }),
      ).shiftDetails.single;

      expect(part.weeklys, hasLength(2));
      expect(part.weeklys[0].weeklyDay, 'SAT');
      expect(part.weeklys[0].startTime, '08:00:00');
      expect(part.weeklys[0].endTime, '12:00:00');
      expect(part.weeklys[1].weeklyDay, 'MON');
      expect(part.weeklys[1].endTime, '18:00');
    });

    test('an empty list, a missing key, null and a non-list all give no rows',
        () {
      for (final part in <Map<String, dynamic>>[
        {'id': 'p', 'weeklys': <dynamic>[]},
        {'id': 'p'},
        {'id': 'p', 'weeklys': null},
        {'id': 'p', 'weeklys': 'none'},
        {
          'id': 'p',
          'weeklys': {'weekly_day': 'SAT'},
        },
      ]) {
        final detail = EmployeeProfileModel.fromJson(
          profileWith(part),
        ).shiftDetails.single;

        expect(detail.weeklys, isEmpty, reason: '$part');
      }
    });

    test('a row with no weekly_day cannot be placed on a day and is skipped',
        () {
      final part = EmployeeProfileModel.fromJson(
        profileWith({
          'id': 'p',
          'weeklys': [
            {'start_time': '08:00', 'end_time': '12:00'},
            'junk',
            {'weekly_day': 'SUN', 'start_time': '10:00', 'end_time': '14:00'},
          ],
        }),
      ).shiftDetails.single;

      expect(part.weeklys.single.weeklyDay, 'SUN');
    });
  });

  group('can_ask_ot (may this employee ask for OT)', () {
    test('true and false are read as sent', () {
      expect(
        EmployeeProfileModel.fromJson({'id': 'e', 'can_ask_ot': true}).canAskOt,
        isTrue,
      );
      expect(
        EmployeeProfileModel.fromJson({'id': 'e', 'can_ask_ot': false}).canAskOt,
        isFalse,
      );
    });

    test('missing, null or not a bool is unknown (null), not false', () {
      expect(EmployeeProfileModel.fromJson({'id': 'e'}).canAskOt, isNull);
      expect(
        EmployeeProfileModel.fromJson({'id': 'e', 'can_ask_ot': null}).canAskOt,
        isNull,
      );
      expect(
        EmployeeProfileModel.fromJson({'id': 'e', 'can_ask_ot': 'false'})
            .canAskOt,
        isNull,
      );
    });
  });
}
