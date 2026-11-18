import '../../../time_off/data/models/leave_parse.dart';
import '../../domain/entities/time_correction_status.dart';
import '../../domain/entities/time_correction_type.dart';

/// JSON coercion shared by the time-correction list and detail models.
class TimeCorrectionJson {
  TimeCorrectionJson._();

  /// An id or other scalar as text; null when missing or empty.
  static String? text(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static TimeCorrectionType? type(dynamic value) {
    for (final type in TimeCorrectionType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }

  /// Anything not yet decided reads as pending.
  static TimeCorrectionStatus status(dynamic value) =>
      switch (LeaveJson.str(value)?.toLowerCase()) {
        'approved' => TimeCorrectionStatus.approved,
        'rejected' || 'declined' => TimeCorrectionStatus.rejected,
        'cancelled' || 'canceled' => TimeCorrectionStatus.cancelled,
        _ => TimeCorrectionStatus.pending,
      };

  /// `HH:mm`, `HH:mm:ss` or a full ISO timestamp, as an offset from midnight.
  static Duration? timeOfDay(dynamic value) {
    final text = LeaveJson.nonEmpty(value);
    if (text == null) return null;

    final instant = text.contains('T') ? DateTime.tryParse(text) : null;
    if (instant != null) {
      final local = instant.toLocal();
      return Duration(hours: local.hour, minutes: local.minute);
    }

    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return Duration(hours: hour, minutes: minute);
  }

  /// A company wall-clock time (`attendance_record`'s `clock_in`, #45), as
  /// written: `2026-11-14 17:05:00`, `2026-11-14T17:05:00`, or `17:05` on
  /// [day].
  ///
  /// A time with no zone is the company's clock as written, never shifted.
  /// One that carries a zone (`Z`, `+07:00`) is a moment, read the way the
  /// history page reads `records/my` (`AttendanceRecordModel`): on the
  /// phone's clock, so the corrected day and the history row always show the
  /// same time. A bare date has no time: null.
  static DateTime? wallClock(dynamic value, {DateTime? day}) {
    final text = LeaveJson.nonEmpty(value)?.trim();
    if (text == null) return null;

    final timeOnly = _timeOnly.firstMatch(text);
    if (timeOnly != null) {
      if (day == null) return null;
      return DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(timeOnly[1]!),
        int.parse(timeOnly[2]!),
        int.parse(timeOnly[3] ?? '0'),
      );
    }

    if (!_hasTime.hasMatch(text)) return null;
    final parsed = DateTime.tryParse(text);
    return parsed != null && parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static final RegExp _timeOnly = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  /// A date with a time of day after it (`T` or a space, then `HH:MM`).
  static final RegExp _hasTime = RegExp(r'\d[T ]\d{1,2}:\d{2}');

  /// The evidence arrives as a bare URL, the `POST /uploads` object, or a
  /// list of either; `""` or null means none.
  static List<String> attachmentUrls(dynamic value) {
    if (value is List) return value.expand(attachmentUrls).toList();
    final url = LeaveJson.nonEmpty(value is Map ? value['url'] : value);
    return url == null ? const [] : [url];
  }
}
