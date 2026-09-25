import '../../../time_off/data/models/leave_parse.dart';
import '../../../time_off/domain/entities/leave_approval_step.dart';
import '../../domain/entities/time_correction_detail.dart';
import 'time_correction_parse.dart';

/// Reads `GET /attendance/correction-requests/:id`'s `data` object.
///
/// Throws [FormatException] when the id, date or correction type is missing
/// — the page has nothing meaningful to show without them.
class TimeCorrectionDetailModel {
  const TimeCorrectionDetailModel._();

  static TimeCorrectionDetail fromJson(Map<String, dynamic> json) {
    final id = TimeCorrectionJson.text(json['id']);
    final requestDate = LeaveJson.date(json['request_date']);
    final type = TimeCorrectionJson.type(json['correction_type']);
    if (id == null || requestDate == null || type == null) {
      throw const FormatException('Incomplete correction request');
    }

    final steps = LeaveJson.objects(json['steps']).map(_step).toList()
      ..sort((a, b) => a.stepNo.compareTo(b.stepNo));

    return TimeCorrectionDetail(
      id: id,
      employee: _employee(json['employee']),
      requestDate: requestDate,
      type: type,
      clockIn: TimeCorrectionJson.timeOfDay(json['requested_clock_in']),
      clockOut: TimeCorrectionJson.timeOfDay(json['requested_clock_out']),
      shift: _shift(json['shift_detail']),
      reason: LeaveJson.str(json['reason']) ?? '',
      attachmentUrl: TimeCorrectionJson.attachmentUrls(
        json['attachment_url'],
      ).firstOrNull,
      status: TimeCorrectionJson.status(json['status']),
      currentStepNo: LeaveJson.intOf(json['current_step_no']) ?? 0,
      steps: steps,
      submittedAt: LeaveJson.dateTime(json['created_at']) ?? requestDate,
    );
  }

  static TimeCorrectionEmployee _employee(dynamic value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const {};
    final department = json['department'];
    return TimeCorrectionEmployee(
      name: LeaveJson.nonEmpty(json['name']) ?? '',
      employeeNumber: LeaveJson.nonEmpty(json['employee_number']),
      departmentName: department is Map
          ? LeaveJson.nonEmpty(department['name'])
          : LeaveJson.nonEmpty(json['department_name']),
      departmentNameLo: department is Map
          ? LeaveJson.nonEmpty(department['name_lo'])
          : null,
    );
  }

  static TimeCorrectionShift? _shift(dynamic value) {
    if (value is! Map) return null;
    final shift = value['shift'];
    return TimeCorrectionShift(
      name: LeaveJson.nonEmpty(value['name']),
      nameLo: LeaveJson.nonEmpty(value['name_lo']),
      start: TimeCorrectionJson.timeOfDay(value['start_time']),
      end: TimeCorrectionJson.timeOfDay(value['end_time']),
      breakMinutes: LeaveJson.intOf(value['break_minutes']),
      overtimeEligible: LeaveJson.boolOf(value['overtime_eligible']),
      shiftName: shift is Map ? LeaveJson.nonEmpty(shift['name']) : null,
      shiftNameLo: shift is Map ? LeaveJson.nonEmpty(shift['name_lo']) : null,
      shiftCode: shift is Map ? LeaveJson.nonEmpty(shift['code']) : null,
    );
  }

  static TimeCorrectionApprovalStep _step(Map<String, dynamic> json) {
    final approver = json['approver'];
    return TimeCorrectionApprovalStep(
      stepNo: LeaveJson.intOf(json['step_no']) ?? 0,
      role: LeaveApprovalStep.roleFromWire(LeaveJson.str(json['step_role'])),
      approverName: approver is Map
          ? LeaveJson.nonEmpty(approver['name'])
          : null,
      status: LeaveApprovalStep.statusFromWire(LeaveJson.str(json['status'])),
      note: LeaveJson.nonEmpty(json['note']),
      createdAt: LeaveJson.dateTime(json['created_at']),
      actedAt: LeaveJson.dateTime(json['acted_at']),
    );
  }
}
