/// The small readers behind the OT models. None of them throws: a field of
/// the wrong type, or none at all, is null (or the fallback), never a crash.
/// Same tolerant style as `time_off/data/models/leave_parse.dart`, without
/// its `as num?` casts, which throw on text.
///
/// The server sends two time formats in one answer:
/// * [instant]: Go `time.Time`, RFC 3339 with its offset
///   (`2026-11-14T18:00:00+07:00`) for `starts_at`, `ends_at`, piece times
///   and `join_deadline`;
/// * [wallClock]: the attendance `DateTime`, `2026-11-11 09:30:00` with no
///   `T` and no zone, for `created_at`, `updated_at`, `acted_at` and
///   `paid_by_hand_at`. The server writes it in Lao time.
class OtJson {
  OtJson._();

  static String? str(dynamic value) => value is String ? value : null;

  static String? nonEmpty(dynamic value) {
    final text = str(value);
    return (text == null || text.isEmpty) ? null : text;
  }

  static bool boolOf(dynamic value, {bool fallback = false}) =>
      value is bool ? value : fallback;

  /// A whole number (`3` or `3.0`), else null: `3.7`, `"3"` and NaN are not.
  static int? intOf(dynamic value) {
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    return null;
  }

  /// A calendar day (`YYYY-MM-DD`), kept as that day with no time and no
  /// zone shift. Only the date part is read, so a day sent with a time and
  /// an offset is still its own day on any phone.
  static DateTime? date(dynamic value) {
    final text = nonEmpty(value);
    if (text == null || text.length < 10) return null;
    final head = text.substring(0, 10);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(head)) return null;
    final parsed = DateTime.tryParse(head);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// A moment, RFC 3339 with its offset, on the phone's clock.
  static DateTime? instant(dynamic value) {
    final text = nonEmpty(value);
    return text == null ? null : DateTime.tryParse(text)?.toLocal();
  }

  /// `2026-11-11 09:30:00`, Lao wall-clock time with no zone: read as that
  /// time on the phone's clock (09:30 stays 09:30), never as UTC. A value
  /// that does carry a zone is read as that moment instead.
  static DateTime? wallClock(dynamic value) {
    final text = nonEmpty(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    // No zone in the text: Dart reads it as local time already. With one,
    // it comes back as UTC and is moved to the phone's clock.
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  /// A JSON object, or null.
  static Map<String, dynamic>? object(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  /// The objects of a list; anything else in it, or no list, is left out.
  static List<Map<String, dynamic>> objects(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
