import '../../domain/entities/ot_step.dart';
import 'ot_parse.dart';

/// Reads one approval step (`steps[]`). Never throws.
class OtStepModel {
  OtStepModel._();

  static OtStep fromJson(Map<String, dynamic> json) {
    final approver = OtJson.object(json['approver']);
    return OtStep(
      id: OtJson.str(json['id']) ?? '',
      stepNo: OtJson.intOf(json['step_no']) ?? 0,
      role: switch (json['step_role']) {
        'dept_head' => OtStepRole.deptHead,
        'hr' => OtStepRole.hr,
        _ => OtStepRole.unknown,
      },
      approverId: OtJson.nonEmpty(approver?['id']),
      approverName: OtJson.nonEmpty(approver?['name']),
      status: switch (json['status']) {
        'waiting' => OtStepStatus.waiting,
        'pending' => OtStepStatus.pending,
        'approved' => OtStepStatus.approved,
        'rejected' => OtStepStatus.rejected,
        _ => OtStepStatus.unknown,
      },
      note: OtJson.nonEmpty(json['note']),
      actedAt: OtJson.wallClock(json['acted_at']),
      createdAt: OtJson.wallClock(json['created_at']),
    );
  }
}
