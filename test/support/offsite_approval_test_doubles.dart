import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';

/// An off-site scan waiting at one step (#46): an HR step by default, or a
/// dept-head / `specific` step naming [approverId].
OffsiteRequestDetail offsiteForApproval({
  String id = 'o-1',
  String employeeId = 'e-noy',
  TimeCorrectionStatus status = TimeCorrectionStatus.pending,
  LeaveStepRole role = LeaveStepRole.hr,
  String? approverId,
  LeaveStepStatus stepStatus = LeaveStepStatus.pending,
  OffsiteMethod method = OffsiteMethod.checkIn,
}) => OffsiteRequestDetail(
  id: id,
  employee: TimeCorrectionEmployee(
    id: employeeId,
    name: 'Noy Phommachanh',
    employeeNumber: 'EMP-001',
  ),
  method: method,
  latitude: 17.9757,
  longitude: 102.6331,
  scanTimestamp: DateTime(2026, 11, 18, 8, 15),
  scanDate: DateTime(2026, 11, 18),
  sessionOrder: 1,
  shift: null,
  attachmentUrl: null,
  reason: 'At a client',
  status: status,
  currentStepNo: 1,
  attendanceRecordId: null,
  steps: [
    TimeCorrectionApprovalStep(
      id: 'step-1',
      stepNo: 1,
      role: role,
      approverId: approverId,
      status: stepStatus,
    ),
  ],
  submittedAt: DateTime(2026, 11, 18, 8, 15),
);
