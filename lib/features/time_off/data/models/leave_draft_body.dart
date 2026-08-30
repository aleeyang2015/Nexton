import '../../domain/entities/leave_request_draft.dart';

/// Builds the JSON body for `POST /leave/requests` and `PUT /leave/requests/:id`
/// (leave-request-flutter.md §3.3/§3.4).
///
/// The form always picks individual days, so this always sends `dates[]` (never
/// the `start_date`+`end_date` range mode). On edit every field is optional on
/// the wire, but sending the whole draft is valid and keeps the backend's
/// `total_days` / balance recompute unambiguous.
class LeaveDraftBody {
  const LeaveDraftBody._();

  static Map<String, dynamic> from(LeaveRequestDraft draft) {
    final sorted = [...draft.dates]..sort();
    return {
      'leave_type_id': draft.leaveTypeId,
      'dates': sorted.map(_isoDate).toList(),
      'duration_type': draft.durationType.wireValue,
      if (draft.returnDate != null) 'return_date': _isoDate(draft.returnDate!),
      if (draft.reason.trim().isNotEmpty) 'reason': draft.reason.trim(),
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
