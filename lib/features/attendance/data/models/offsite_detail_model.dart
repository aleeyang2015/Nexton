import '../../../time_off/data/models/leave_parse.dart';
import '../../../time_off/domain/entities/leave_approval_step.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/time_correction_detail.dart';
import 'offsite_submission_model.dart';
import 'time_correction_parse.dart';

/// Reads an `OffsiteRequestResponse` object (§3, §10) — the shape the detail,
/// `my` and `my-approvals` endpoints all answer with.
///
/// Throws [FormatException] when the id or the method is missing: a request
/// whose direction is unknown can't be shown, since "clock in" and "clock out"
/// is the first thing an approver reads.
class OffsiteDetailModel {
  const OffsiteDetailModel._();

  static OffsiteRequestDetail fromJson(Map<String, dynamic> json) {
    final id = TimeCorrectionJson.text(json['id']);
    final method = OffsiteMethod.fromWire(LeaveJson.str(json['method']));
    if (id == null || method == null) {
      throw const FormatException('Incomplete off-site request');
    }

    final steps = LeaveJson.objects(json['steps']).map(_step).toList()
      ..sort((a, b) => a.stepNo.compareTo(b.stepNo));

    // Wall clocks, never shifted into UTC (§11.4). `scan_date` is a calendar
    // day, so it keeps only its date part.
    final scanTimestamp = OffsiteSubmissionModel.wallClock(
      json['scan_timestamp'],
    );
    final createdAt = OffsiteSubmissionModel.wallClock(json['created_at']);

    return OffsiteRequestDetail(
      id: id,
      employee: _employee(json['employee']),
      method: method,
      latitude: LeaveJson.doubleOf(json['latitude']),
      longitude: LeaveJson.doubleOf(json['longitude']),
      scanTimestamp: scanTimestamp,
      scanDate: LeaveJson.date(json['scan_date']) ?? _dateOnly(scanTimestamp),
      sessionOrder: LeaveJson.intOf(json['session_order']) ?? 0,
      shift: _shift(json['shift_detail']),
      attachmentUrl: TimeCorrectionJson.attachmentUrls(
        json['attachment'],
      ).firstOrNull,
      reason: LeaveJson.str(json['reason']) ?? '',
      status: TimeCorrectionJson.status(json['status']),
      currentStepNo: LeaveJson.intOf(json['current_step_no']) ?? 0,
      attendanceRecordId: LeaveJson.nonEmpty(json['attendance_record_id']),
      steps: steps,
      submittedAt: createdAt ?? scanTimestamp ?? DateTime.now(),
    );
  }

  /// §10's `OffsiteEmployee`, which carries the same fields the correction
  /// workflow's employee block does.
  static TimeCorrectionEmployee _employee(dynamic value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const {};
    final department = json['department'];
    return TimeCorrectionEmployee(
      name: LeaveJson.nonEmpty(json['name']) ?? '',
      employeeNumber: LeaveJson.nonEmpty(json['employee_number']),
      departmentName: department is Map
          ? LeaveJson.nonEmpty(department['name'])
          : null,
      departmentNameLo: department is Map
          ? LeaveJson.nonEmpty(department['name_lo'])
          : null,
    );
  }

  /// §10's `ShiftDetailRef` — the same object `shift_detail` holds on a
  /// correction request.
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

  /// §10's `OffsiteStep`, field for field the correction workflow's step.
  static TimeCorrectionApprovalStep _step(Map<String, dynamic> json) {
    final approver = json['approver'];
    return TimeCorrectionApprovalStep(
      id: LeaveJson.nonEmpty(json['id']),
      stepNo: LeaveJson.intOf(json['step_no']) ?? 0,
      // `specific` is an off-site role the shared enum doesn't name; it falls
      // through to `unknown`, which the timeline renders by its approver's name.
      role: LeaveApprovalStep.roleFromWire(LeaveJson.str(json['step_role'])),
      approverName: approver is Map
          ? LeaveJson.nonEmpty(approver['name'])
          : null,
      status: LeaveApprovalStep.statusFromWire(LeaveJson.str(json['status'])),
      note: LeaveJson.nonEmpty(json['note']),
      createdAt: OffsiteSubmissionModel.wallClock(json['created_at']),
      actedAt: OffsiteSubmissionModel.wallClock(json['acted_at']),
    );
  }

  static DateTime? _dateOnly(DateTime? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);
}
