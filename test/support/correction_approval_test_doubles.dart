import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';

/// A "forgot to scan" request waiting at one step (#47): an HR step by
/// default, or a dept-head / `specific` step naming [approverId].
TimeCorrectionDetail correctionForApproval({
  String id = 'tc-1',
  String employeeId = 'e-noy',
  TimeCorrectionStatus status = TimeCorrectionStatus.pending,
  LeaveStepRole role = LeaveStepRole.hr,
  String? approverId,
  LeaveStepStatus stepStatus = LeaveStepStatus.pending,
  TimeCorrectionResult? result,
}) => TimeCorrectionDetail(
  id: id,
  employee: TimeCorrectionEmployee(
    id: employeeId,
    name: 'Noy Phommachanh',
    employeeNumber: 'EMP-001',
  ),
  requestDate: DateTime(2026, 11, 14),
  type: TimeCorrectionType.forgotClockOut,
  clockIn: null,
  clockOut: const Duration(hours: 17, minutes: 5),
  shift: const TimeCorrectionShift(
    name: 'Morning',
    nameLo: 'ຊ່ວງເຊົ້າ',
    start: Duration(hours: 8),
    end: Duration(hours: 17),
  ),
  reason: 'Forgot to clock out',
  attachmentUrl: null,
  status: status,
  currentStepNo: 1,
  steps: [
    TimeCorrectionApprovalStep(
      id: 'step-1',
      stepNo: 1,
      role: role,
      approverId: approverId,
      status: stepStatus,
    ),
  ],
  submittedAt: DateTime(2026, 11, 15, 9),
  result: result,
);
