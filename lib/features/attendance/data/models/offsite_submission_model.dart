import '../../domain/entities/offsite_outcome.dart';

/// Reads the part of `OffsiteRequestResponse` the submit form reports on (§3).
///
/// The rest of the response — the employee, the shift segment, the approval
/// steps — is what the request list and its detail view are for, and is left
/// unparsed rather than modelled before anything reads it.
class OffsiteSubmissionModel {
  const OffsiteSubmissionModel._();

  static OffsiteSubmission fromJson(Map<String, dynamic> json) {
    final status = _text(json['status']) ?? '';

    return OffsiteSubmission(
      autoApproved: status.toLowerCase() == 'approved',
      scanTimestamp: wallClock(json['scan_timestamp']),
      sessionOrder: (json['session_order'] as num?)?.toInt(),
      attendanceRecordId: _text(json['attendance_record_id']),
      rawStatus: status,
    );
  }

  /// `"2026-10-02 08:15:00"` — a tenant-local wall clock with no timezone
  /// suffix (§1).
  ///
  /// Parsed as-is and never shifted: §11.4 warns that treating these as
  /// ISO-8601 instants reads them as UTC and moves every time by the device's
  /// offset. `DateTime.parse` keeps a suffix-less stamp local, so the only
  /// thing to be careful about is not calling `toUtc`/`toLocal` on the result.
  static DateTime? wallClock(dynamic value) {
    final text = _text(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
