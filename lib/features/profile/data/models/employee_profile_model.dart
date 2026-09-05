import '../../domain/entities/employee_profile.dart';
import '../../domain/entities/shift_detail.dart';

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
    );
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
            name: _nonEmpty(_string(raw['name'])),
            nameLo: _nonEmpty(_string(raw['name_lo'])),
            startTime: _nonEmpty(_string(raw['start_time'])),
            endTime: _nonEmpty(_string(raw['end_time'])),
          ),
        )
        .toList(growable: false);
  }

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
