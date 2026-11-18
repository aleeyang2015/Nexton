import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/profile/data/models/employee_profile_model.dart';
import 'package:next_on/features/profile/domain/entities/personal_info.dart';

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

    test('reads each part\'s early and late minutes, and a weekly row\'s own '
        '(#43); missing or odd values read as none', () {
      final profile = EmployeeProfileModel.fromJson({
        'id': '1',
        'full_name': 'Somphone Vilaysone',
        'shift': {
          'id': 'shift-1',
          'shift_details': [
            {
              'id': 'p1',
              'start_time': '08:00:00',
              'end_time': '17:00:00',
              'early_checkin_minutes': 30,
              'late_checkout_minutes': 60,
              'weeklys': [
                {
                  'weekly_day': 'SAT',
                  'end_time': '12:00:00',
                  'late_checkout_minutes': 15,
                },
              ],
            },
            {
              'id': 'p2',
              'start_time': '13:00:00',
              'end_time': '17:00:00',
              'early_checkin_minutes': 'soon',
            },
          ],
        },
      });

      final office = profile.shiftDetails[0];
      expect(office.earlyCheckinMinutes, 30);
      expect(office.lateCheckoutMinutes, 60);
      final saturday = office.weeklys.single;
      expect(saturday.lateCheckoutMinutes, 15);
      expect(saturday.earlyCheckinMinutes, isNull);
      // 2026-11-14 is a Saturday: its own late minutes, the part's early.
      expect(office.minutesOn(DateTime(2026, 11, 14)), (early: 30, late: 15));

      expect(profile.shiftDetails[1].earlyCheckinMinutes, 0);
      expect(profile.shiftDetails[1].lateCheckoutMinutes, 0);
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

  group('personal info (#58)', () {
    Map<String, dynamic> full() => {
      'id': 'emp-1',
      'first_name': ' Bee ',
      'last_name': 'Sisouk',
      'first_name_lo': 'ບີ',
      'last_name_lo': 'ສີສຸກ',
      'employee_number': 'EMP-0042',
      'mobile_phone': '020 5555 1234',
      'work_phone': '021 412 000',
      'work_phone_extension': '12',
      'home_phone': '021 300 300',
      'department_name': 'Finance',
      'reports_to_name': 'Noy Phommachanh',
      'hire_date': '2024-01-15T00:00:00+07:00',
      'emergency_contacts': [
        {
          'name': 'Keo Sisouk',
          'name_lo': 'ແກ້ວ ສີສຸກ',
          'relationship': 'spouse',
          'phone': '020 7777 0000',
          'phone_secondary': '030 1111 2222',
          'address': 'Vientiane',
        },
        {'name': 'Somchai', 'relationship': 'cousin'},
      ],
      // Sensitive: never read.
      'base_salary': 8800000,
      'national_id': 'ID-123456789',
      'passport_number': 'PA-7654321',
      'social_security_number': 'SSN-1122',
      'tax_id': 'TAX-998877',
      'bank_account_number': 'BANK-445566',
      'bank_name': 'BCEL',
    };

    test('every field, trimmed', () {
      final p = EmployeeProfileModel.fromJson(full()).personal;
      expect(p.firstName, 'Bee');
      expect(p.lastName, 'Sisouk');
      expect(p.name, 'Bee Sisouk');
      expect(p.nameLo, 'ບີ ສີສຸກ');
      expect(p.employeeNumber, 'EMP-0042');
      expect(p.mobilePhone, '020 5555 1234');
      expect(p.workPhone, '021 412 000');
      expect(p.workPhoneExtension, '12');
      expect(p.homePhone, '021 300 300');
      expect(p.departmentName, 'Finance');
      expect(p.managerName, 'Noy Phommachanh');
      expect(p.hireDate, DateTime(2024, 1, 15));
      expect(p.emergencyContacts, const [
        EmergencyContact(
          name: 'Keo Sisouk',
          nameLo: 'ແກ້ວ ສີສຸກ',
          relationship: 'spouse',
          phone: '020 7777 0000',
          phoneSecondary: '030 1111 2222',
        ),
        // An unknown relationship is kept as sent.
        EmergencyContact(name: 'Somchai', relationship: 'cousin'),
      ]);
    });

    test('the optional fields missing: none, no crash', () {
      final p = EmployeeProfileModel.fromJson({
        'id': 'emp-1',
        'first_name': 'Bee',
        'last_name': 'Sisouk',
        'employee_number': 'EMP-0042',
        'hire_date': '2024-01-15T00:00:00Z',
      }).personal;
      expect(p.nameLo, isNull);
      expect(p.mobilePhone, isNull);
      expect(p.workPhone, isNull);
      expect(p.workPhoneExtension, isNull);
      expect(p.homePhone, isNull);
      expect(p.departmentName, isNull);
      expect(p.managerName, isNull);
      expect(p.emergencyContacts, isEmpty);
    });

    test('empty texts are none; no manager (" ") is none', () {
      final p = EmployeeProfileModel.fromJson({
        ...full(),
        'mobile_phone': '   ',
        'reports_to_name': ' ',
        'first_name_lo': '',
        'last_name_lo': null,
      }).personal;
      expect(p.mobilePhone, isNull);
      expect(p.managerName, isNull);
      expect(p.nameLo, isNull);
    });

    test('emergency contacts in a bad shape', () {
      for (final bad in <Object?>[
        null,
        'Keo 020 7777',
        {'name': 'Keo'},
        42,
      ]) {
        expect(
          EmployeeProfileModel.fromJson({
            ...full(),
            'emergency_contacts': bad,
          }).personal.emergencyContacts,
          isEmpty,
          reason: '$bad',
        );
      }
      final p = EmployeeProfileModel.fromJson({
        ...full(),
        'emergency_contacts': [
          'not an object',
          {'relationship': 'parent', 'phone': '020'},
          {'name': '  '},
          {'name': 'Keo', 'phone': 2055550000},
        ],
      }).personal;
      expect(p.emergencyContacts, const [
        EmergencyContact(name: 'Keo', phone: '2055550000'),
      ]);
    });

    test('a hire date that is not a date: none, never a crash', () {
      for (final bad in <Object?>['soon', '', '2024-02-31T00:00:00Z', 20240115, null]) {
        expect(
          EmployeeProfileModel.fromJson({
            ...full(),
            'hire_date': bad,
          }).personal.hireDate,
          isNull,
          reason: '$bad',
        );
      }
    });

    test('the hire date is the day as sent, whatever the zone', () {
      for (final sent in [
        '2024-01-15T00:00:00+07:00',
        '2024-01-15T23:30:00-05:00',
        '2024-01-15',
      ]) {
        expect(
          EmployeeProfileModel.fromJson({
            ...full(),
            'hire_date': sent,
          }).personal.hireDate,
          DateTime(2024, 1, 15),
          reason: sent,
        );
      }
    });

    test('no salary, ID, passport, tax, social security or bank value is '
        'kept anywhere in the profile', () {
      final profile = EmployeeProfileModel.fromJson(full());
      final kept = '${profile.props} ${profile.personal.props}';
      for (final secret in [
        '8800000',
        'ID-123456789',
        'PA-7654321',
        'SSN-1122',
        'TAX-998877',
        'BANK-445566',
        'BCEL',
      ]) {
        expect(kept, isNot(contains(secret)), reason: secret);
      }
    });
  });
}
