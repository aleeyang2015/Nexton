import '../../../time_off/data/models/leave_parse.dart';
import '../../domain/entities/time_correction_record.dart';
import 'time_correction_parse.dart';

/// Reads one entry of `GET /attendance/correction-requests/my`.
///
/// Same fields as the detail response ([TimeCorrectionDetailModel]), with the
/// usual alternates accepted. An entry without an id, a date or a known
/// correction type is dropped rather than shown half-empty.
class TimeCorrectionRecordModel {
  const TimeCorrectionRecordModel._();

  static TimeCorrectionRecord? fromJson(Map<String, dynamic> json) {
    final id = TimeCorrectionJson.text(json['id']);
    final workDate = LeaveJson.date(json['request_date'] ?? json['date']);
    final type = TimeCorrectionJson.type(json['correction_type']);
    if (id == null || workDate == null || type == null) return null;

    return TimeCorrectionRecord(
      id: id,
      submittedAt:
          LeaveJson.dateTime(json['created_at'] ?? json['submitted_at']) ??
          workDate,
      workDate: workDate,
      type: type,
      clockIn: TimeCorrectionJson.timeOfDay(json['requested_clock_in']),
      clockOut: TimeCorrectionJson.timeOfDay(json['requested_clock_out']),
      status: TimeCorrectionJson.status(json['status']),
      attachmentCount: TimeCorrectionJson.attachmentUrls(
        json['attachment_url'] ?? json['attachments'] ?? json['attachment'],
      ).length,
    );
  }
}
