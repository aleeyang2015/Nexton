import '../../domain/entities/punch_receipt.dart';

/// Reads the `data` object of a 200 clock-in/clock-out response (§3).
///
/// Parsing is deliberately forgiving: §3 marks the shift-derived fields
/// (`is_late`, `session_*`) as present only when a shift is configured, and a
/// punch that was genuinely stored must not be reported as a crash because an
/// optional field was absent or arrived as a different numeric type.
class PunchReceiptModel {
  const PunchReceiptModel._();

  static PunchReceipt fromJson(Map<String, dynamic> json) {
    final rawReason = _string(json['rejection_reason']);

    return PunchReceipt(
      checkinId: _string(json['checkin_id']) ?? '',
      // `status` is the field that decides whether the punch counted; fall
      // back to `verification_status`, which §3 sends alongside it.
      verification: PunchVerification.fromWire(
        _string(json['status']) ?? _string(json['verification_status']),
      ),
      message: _string(json['message']) ?? '',
      rejectionReason: PunchRejectionReason.fromWire(rawReason),
      rawRejectionReason: (rawReason?.isEmpty ?? true) ? null : rawReason,
      locationName: _nonEmpty(_string(json['location_name'])),
      distanceFromCenter: _double(json['distance_from_center']),
      timestamp: _timestamp(json['timestamp']),
      isLate: json['is_late'] as bool?,
      lateMinutes: _int(json['late_minutes']),
      attendanceStatus: _nonEmpty(_string(json['attendance_status'])),
      sessionOrder: _int(json['session_order']),
      sessionLabel: _nonEmpty(_string(json['session_label'])),
    );
  }

  /// The API sends UTC (RFC3339); everything downstream shows local time, so
  /// the conversion happens once, here (§7 rule 9).
  ///
  /// An unparseable or missing stamp falls back to "now": the punch is known
  /// to have just happened, and refusing to show a stored punch over a bad
  /// timestamp would be worse than a second's imprecision.
  static DateTime _timestamp(dynamic value) {
    final parsed = DateTime.tryParse(_string(value) ?? '');
    return (parsed ?? DateTime.now()).toLocal();
  }

  static String? _string(dynamic value) => value is String ? value : null;

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  static double? _double(dynamic value) => (value as num?)?.toDouble();

  static int? _int(dynamic value) => (value as num?)?.toInt();
}
