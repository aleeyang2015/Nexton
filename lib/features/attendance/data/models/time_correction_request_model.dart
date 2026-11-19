import '../../domain/entities/time_correction_request.dart';

/// Serialises a [TimeCorrectionRequest] into the
/// `POST /attendance/correction-requests` body.
///
/// Dates and times are formatted by hand, like the rest of this feature's
/// query strings: `DateFormat` would render Lao numerals under the Lao locale.
class TimeCorrectionRequestModel {
  final TimeCorrectionRequest request;

  const TimeCorrectionRequestModel(this.request);

  /// A time the correction type doesn't carry is omitted. `attachment_url`
  /// is always sent, and always as text: the uploaded file's URL when there
  /// is a file, `""` when there isn't. The server reads the field as a
  /// string, so the whole `POST /uploads` object there got every request
  /// with a photo refused (#73).
  Map<String, dynamic> toJson() {
    final type = request.type;
    final clockIn = request.clockIn;
    final clockOut = request.clockOut;
    final attachment = request.attachment;

    return {
      'request_date': _isoDate(request.date),
      'correction_type': type.wireValue,
      if (type.needsClockIn && clockIn != null)
        'requested_clock_in': _hourMinute(clockIn),
      if (type.needsClockOut && clockOut != null)
        'requested_clock_out': _hourMinute(clockOut),
      // Left out when there is none (#43): an empty optional field is not
      // sent.
      if (request.shiftDetailId case final id? when id.isNotEmpty)
        'shift_detail_id': id,
      'attachment_url': attachment?.url ?? '',
      'reason': request.reason.trim(),
    };
  }

  /// `YYYY-MM-DD`.
  static String _isoDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  /// `HH:mm`, from an offset since midnight.
  static String _hourMinute(Duration time) =>
      '${_two(time.inHours)}:${_two(time.inMinutes % 60)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
