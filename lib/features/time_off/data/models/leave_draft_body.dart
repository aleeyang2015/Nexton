import '../../domain/entities/leave_request_draft.dart';
import 'leave_attachment_model.dart';

/// Builds the JSON body for `POST /leave/requests` and `PUT /leave/requests/:id`
/// (leave-request-flutter.md §3.3/§3.4).
///
/// The days go in one of the endpoint's two shapes, never both:
///
/// * a date range — `start_date` + `end_date` and no `dates`. The server
///   lists the days in between that are not company days off and charges
///   those;
/// * separate days — `dates[]`. Every day sent is charged, so the calendar
///   does not offer a day off.
///
/// On edit every field is optional on the wire, but sending the whole draft
/// is valid and keeps the backend's `total_days` / balance recompute
/// unambiguous.
class LeaveDraftBody {
  const LeaveDraftBody._();

  static Map<String, dynamic> from(LeaveRequestDraft draft) {
    final sorted = [...draft.dates]..sort();
    return {
      'leave_type_id': draft.leaveTypeId,
      if (draft.isRange) ...{
        'start_date': _isoDate(draft.startDate!),
        'end_date': _isoDate(draft.endDate!),
      } else
        'dates': sorted.map(_isoDate).toList(),
      'duration_type': draft.durationType.wireValue,
      if (draft.returnDate != null) 'return_date': _isoDate(draft.returnDate!),
      if (draft.reason.trim().isNotEmpty) 'reason': draft.reason.trim(),
      // A list of upload objects. Left out when null, so an edit keeps the
      // files the request has; present (even empty) it replaces them all.
      if (draft.attachments case final files?)
        'attachments': [for (final f in files) LeaveAttachmentModel.toJson(f)],
    };
  }

  /// `YYYY-MM-DD` in the device's own timezone, formatted by hand so the
  /// digits are never rendered in the active locale's numerals.
  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
