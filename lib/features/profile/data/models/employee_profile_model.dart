import '../../domain/entities/employee_profile.dart';

/// Reads `GET /core_hr/employees/me`.
///
/// The exact field spellings for a Core HR employee record aren't
/// documented, so each value is looked up under the names the rest of the
/// API uses, with the plainer alias accepted too — same convention as
/// `AttendanceRecordModel`.
class EmployeeProfileModel {
  const EmployeeProfileModel._();

  static EmployeeProfile fromJson(Map<String, dynamic> json) {
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
    );
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
