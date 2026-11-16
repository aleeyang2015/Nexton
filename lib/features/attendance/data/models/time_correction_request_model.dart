import '../../../time_off/data/models/uploaded_attachment_model.dart';
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
  /// is always sent: the `POST /uploads` object when there is a file, `""`
  /// when there isn't.
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
      'shift_detail_id': request.shiftDetailId,
      'attachment_url': attachment == null
          ? ''
          : UploadedAttachmentModel.toJson(attachment),
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
