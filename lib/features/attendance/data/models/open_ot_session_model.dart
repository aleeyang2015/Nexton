import '../../domain/entities/open_ot_session.dart';

/// Reads `GET /ot-sessions/open`'s `data`. A body with no request id is no
/// session: there would be nothing to clock out of.
class OpenOtSessionModel {
  const OpenOtSessionModel._();

  static OpenOtSession? fromJson(Map<String, dynamic> json) {
    final id = _text(json['overtime_request_id']);
    if (id == null) return null;
    return OpenOtSession(
      overtimeRequestId: id,
      sessionLabel: _text(json['session_label']) ?? '',
      clockIn: _instant(json['clock_in']),
      clockOutUntil: _instant(json['clock_out_until']),
    );
  }

  static String? _text(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  /// RFC 3339 with its offset, on the phone's clock (as the clock answer).
  static DateTime? _instant(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
