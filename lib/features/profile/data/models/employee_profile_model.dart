import '../../domain/entities/employee_profile.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/entities/shift_detail.dart';
import '../../domain/entities/shift_detail_weekly.dart';

/// Reads `GET /core_hr/employees/me`.
///
/// The exact field spellings for a Core HR employee record aren't
/// documented, so each value is looked up under the names the rest of the
/// API uses, with the plainer alias accepted too — same convention as
/// `AttendanceRecordModel`.
class EmployeeProfileModel {
  const EmployeeProfileModel._();

  static EmployeeProfile fromJson(Map<String, dynamic> json) {
    final shift = _shift(json);

    return EmployeeProfile(
      id: _string(json['id']) ?? '',
      fullName: _fullName(json),
      positionTitle: _nonEmpty(
        _string(json['position_title'] ?? json['job_title'] ?? json['title']),
      ),
      departmentName: _nonEmpty(
        _string(json['department_name'] ?? json['department']),
      ),
      email: _nonEmpty(_string(json['work_email'] ?? json['email'])),
      avatarUrl: _nonEmpty(
        _string(
          json['profile_photo_url'] ??
              json['avatar_url'] ??
              json['photo_url'],
        ),
      ),
      shiftName: _nonEmpty(_string(shift?['name'])),
      shiftNameLo: _nonEmpty(_string(shift?['name_lo'])),
      shiftDetails: _shiftDetails(shift),
      // Only a real bool counts: anything else is "the server did not say".
      canAskOt: json['can_ask_ot'] is bool ? json['can_ask_ot'] as bool : null,
      personal: _personal(json),
    );
  }

  /// The personal page's fields (#58), and only those: the answer also
  /// carries salary, ID card, passport, tax, social security and bank
  /// values, which are never read. Every text is trimmed; empty is none.
  static EmployeePersonalInfo _personal(Map<String, dynamic> json) {
    final text = _plainText;
    return EmployeePersonalInfo(
      firstName: text(json['first_name']) ?? '',
      lastName: text(json['last_name']) ?? '',
      firstNameLo: text(json['first_name_lo']),
      lastNameLo: text(json['last_name_lo']),
      employeeNumber: text(json['employee_number']) ?? '',
      mobilePhone: text(json['mobile_phone']),
      workPhone: text(json['work_phone']),
      workPhoneExtension: text(json['work_phone_extension']),
      homePhone: text(json['home_phone']),
      departmentName: text(json['department_name']),
      // `" "` when there is no manager (a CONCAT over a LEFT JOIN): none.
      managerName: text(json['reports_to_name']),
      hireDate: _calendarDate(json['hire_date']),
      emergencyContacts: _emergencyContacts(json['emergency_contacts']),
    );
  }

  /// The `yyyy-MM-dd` an RFC 3339 date-time starts with, as a calendar date:
  /// converting `…T00:00:00+07:00` to another zone would move it a day. Null
  /// when it does not start with a real date.
  static DateTime? _calendarDate(Object? raw) {
    if (raw is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // 2024-02-31 would roll over into March: not a real date.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    // Go's zero time (`0001-01-01`) is "no date set", not a day.
    if (year < 1900) return null;
    return date;
  }

  /// A text the personal page may show: a string (trimmed, empty is none)
  /// or a whole number (a phone or an employee number sent as a number).
  /// An object or a list is none, never its printout: the server does not
  /// check `emergency_contacts`, and nothing nested in it reaches the
  /// screen.
  static String? _plainText(Object? raw) {
    if (raw is String) return _nonEmpty(raw.trim());
    if (raw is int) return '$raw';
    if (raw is double && raw.isFinite && raw == raw.truncateToDouble()) {
      return '${raw.toInt()}';
    }
    return null;
  }

  /// The web's list of `{name, name_lo?, relationship, phone?,
  /// phone_secondary?, address?}`; the server does not check it. Anything
  /// that is not a list is none; an item that is not an object, or has no
  /// name, is skipped.
  static List<EmergencyContact> _emergencyContacts(Object? raw) {
    if (raw is! List) return const [];
    final text = _plainText;
    return [
      for (final item in raw.whereType<Map>())
        if (text(item['name']) case final String name)
          EmergencyContact(
            name: name,
            nameLo: text(item['name_lo']),
            relationship: text(item['relationship']),
            phone: text(item['phone']),
            phoneSecondary: text(item['phone_secondary']),
          ),
    ];
  }

  static Map<String, dynamic>? _shift(Map<String, dynamic> json) {
    final shift = json['shift'];
    return shift is Map ? Map<String, dynamic>.from(shift) : null;
  }

  /// `shift.shift_details[]` — the morning/afternoon segments of the
  /// assigned shift, in whatever order the backend sends them.
  static List<ShiftDetail> _shiftDetails(Map<String, dynamic>? shift) {
    if (shift == null) return const [];

    final details = shift['shift_details'];
    if (details is! List) return const [];

    return details
        .whereType<Map>()
        .map(
          (raw) => ShiftDetail(
            id: _nonEmpty(_string(raw['id'])),
            name: _nonEmpty(_string(raw['name'])),
            nameLo: _nonEmpty(_string(raw['name_lo'])),
            startTime: _nonEmpty(_string(raw['start_time'])),
            endTime: _nonEmpty(_string(raw['end_time'])),
            endsNextDay: raw['ends_next_day'] == true,
            weeklys: _weeklys(raw['weeklys']),
            earlyCheckinMinutes: _minutes(raw['early_checkin_minutes']) ?? 0,
            lateCheckoutMinutes: _minutes(raw['late_checkout_minutes']) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  /// `shift_details[].weeklys[]` — the weekdays with their own times, in the
  /// backend's order. A missing key, `null` or anything that is not a list
  /// reads as "none", and a row with no `weekly_day` cannot be placed on a
  /// day, so it is skipped.
  static List<ShiftDetailWeekly> _weeklys(dynamic raw) {
    if (raw is! List) return const [];

    return [
      for (final row in raw.whereType<Map>())
        if (_nonEmpty(_string(row['weekly_day'])) case final String day)
          ShiftDetailWeekly(
            weeklyDay: day,
            startTime: _nonEmpty(_string(row['start_time'])),
            endTime: _nonEmpty(_string(row['end_time'])),
            earlyCheckinMinutes: _minutes(row['early_checkin_minutes']),
            lateCheckoutMinutes: _minutes(row['late_checkout_minutes']),
          ),
    ];
  }

  /// A count of minutes; null when it is not a whole, non-negative number.
  static int? _minutes(dynamic raw) =>
      raw is num && raw >= 0 ? raw.toInt() : null;

  static String _fullName(Map<String, dynamic> json) {
    final full = _nonEmpty(_string(json['full_name']));
    if (full != null) return full;

    final first = _string(json['first_name']) ?? '';
    final last = _string(json['last_name']) ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;

    return _string(json['name']) ?? '';
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    return value is String ? value : value.toString();
  }

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
