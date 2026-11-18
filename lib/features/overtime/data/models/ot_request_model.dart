import '../../domain/entities/ot_request.dart';
import 'ot_parse.dart';
import 'ot_piece_model.dart';
import 'ot_step_model.dart';

/// Reads an OT request (`OTRequestResponse`).
///
/// Tolerant: a field missing or of the wrong type gets its empty value, so
/// one odd field never loses the request. The one thing refused is a
/// request with no id ([FormatException]): nothing could open it. Keys the
/// App does not use (`warnings` on a decision, `paid_by_hand_by`) are
/// ignored.
class OtRequestModel {
  OtRequestModel._();

  /// [fromJson], or null for a row that cannot be read: a list skips it
  /// rather than losing the whole page.
  static OtRequest? tryFromJson(Map<String, dynamic> json) {
    try {
      return fromJson(json);
    } on FormatException {
      return null;
    }
  }

  static OtRequest fromJson(Map<String, dynamic> json) {
    final id = OtJson.nonEmpty(json['id']);
    if (id == null) {
      throw const FormatException('An OT request without an id');
    }
    final employee = OtJson.object(json['employee']);
    final department = OtJson.object(employee?['department']);

    return OtRequest(
      id: id,
      employeeId:
          OtJson.nonEmpty(json['employee_id']) ??
          OtJson.nonEmpty(employee?['id']) ??
          '',
      employeeName: OtJson.nonEmpty(employee?['name']),
      employeeNumber: OtJson.nonEmpty(employee?['employee_number']),
      // The current department (#48); `name_lo` may be null.
      departmentName: OtJson.nonEmpty(department?['name']),
      departmentNameLo: OtJson.nonEmpty(department?['name_lo']),
      announcementId: OtJson.nonEmpty(json['announcement_id']),
      workDate: OtJson.date(json['work_date']),
      startTime: OtJson.str(json['start_time']) ?? '',
      endTime: OtJson.str(json['end_time']) ?? '',
      endsNextDay: OtJson.boolOf(json['ends_next_day']),
      startsAt: OtJson.instant(json['starts_at']),
      endsAt: OtJson.instant(json['ends_at']),
      reason: OtJson.nonEmpty(json['reason']),
      agreementNote: OtJson.nonEmpty(json['agreement_note']),
      status: switch (json['status']) {
        'pending' => OtStatus.pending,
        'approved' => OtStatus.approved,
        'rejected' => OtStatus.rejected,
        'cancelled' => OtStatus.cancelled,
        _ => OtStatus.unknown,
      },
      currentStepNo: OtJson.intOf(json['current_step_no']) ?? 0,
      hrOnly: OtJson.boolOf(json['hr_only']),
      didNotCome: OtJson.boolOf(json['did_not_come']),
      paidByHandAt: OtJson.wallClock(json['paid_by_hand_at']),
      createdAt: OtJson.wallClock(json['created_at']),
      updatedAt: OtJson.wallClock(json['updated_at']),
      steps: OtJson.objects(json['steps']).map(OtStepModel.fromJson).toList(),
      pieces: OtJson.objects(json['pieces']).map(OtPieceModel.fromJson).toList(),
    );
  }
}
