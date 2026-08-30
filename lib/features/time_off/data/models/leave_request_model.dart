import '../../domain/entities/leave_attachment.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_type.dart';
import 'leave_attachment_model.dart';
import 'leave_parse.dart';
import 'leave_request_step_model.dart';

/// Reads a `LeaveRequestResponse` (leave-request-flutter.md §3.6) — the shape
/// `GET /leave/requests/my`, the detail endpoint, `my-approvals`, and every
/// mutation (`POST`/`PUT .../approve`/...) all answer with.
class LeaveRequestModel {
  const LeaveRequestModel._();

  static LeaveRequest fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final employeeMap = employee is Map
        ? Map<String, dynamic>.from(employee)
        : const <String, dynamic>{};

    final start = LeaveJson.date(json['start_date']);
    final end = LeaveJson.date(json['end_date']);

    return LeaveRequest(
      id: LeaveJson.str(json['id']) ?? '',
      employeeName: LeaveJson.str(employeeMap['name']) ?? '',
      employeeNumber: LeaveJson.nonEmpty(employeeMap['employee_number']),
      departmentName: LeaveJson.nonEmpty(employeeMap['department_name']),
      leaveType: _leaveType(json['leave_type']),
      startDate: start ?? end ?? DateTime.now(),
      endDate: end ?? start ?? DateTime.now(),
      requestDays: _dateList(json['request_days']),
      returnDate: LeaveJson.date(json['return_date']),
      totalDays: LeaveJson.doubleOr(json['total_days'], 0),
      durationType: LeaveDurationType.fromWire(
        LeaveJson.str(json['duration_type']),
      ),
      reason: LeaveJson.str(json['reason']) ?? '',
      status: _status(json['status']),
      currentStepNo: LeaveJson.intOf(json['current_step_no']),
      steps: LeaveJson.objects(
        json['steps'],
      ).map(LeaveRequestStepModel.fromJson).toList(),
      attachments: _attachments(json['attachments']),
      createdAt: LeaveJson.dateTime(json['created_at']),
    );
  }

  static List<DateTime> _dateList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(LeaveJson.date)
        .whereType<DateTime>()
        .toList(growable: false);
  }

  static LeaveType _leaveType(dynamic value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : null;
    return LeaveType(
      id: LeaveJson.str(map?['id']) ?? '',
      code: LeaveJson.str(map?['code']) ?? '',
      name: LeaveJson.str(map?['name']) ?? '',
      nameLo: LeaveJson.nonEmpty(map?['name_lo']),
      color: LeaveJson.nonEmpty(map?['color']),
    );
  }

  static LeaveStatus _status(dynamic value) => switch (LeaveJson.str(value)) {
    'approved' => LeaveStatus.approved,
    'rejected' => LeaveStatus.rejected,
    'cancelled' => LeaveStatus.cancelled,
    _ => LeaveStatus.pending,
  };

  static List<LeaveAttachment> _attachments(dynamic value) {
    return LeaveJson.objects(
      value,
    ).map(LeaveAttachmentModel.fromJson).whereType<LeaveAttachment>().toList();
  }
}
