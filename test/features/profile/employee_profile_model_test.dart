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
}
