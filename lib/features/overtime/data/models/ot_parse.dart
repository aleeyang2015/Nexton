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
  ///
  /// A day that does not exist (`2026-02-30`, `2026-13-45`) is null, not
  /// rolled over into another one.
  static DateTime? date(dynamic value) {
    final text = nonEmpty(value);
    if (text == null || text.length < 10) return null;
    final match = _day.firstMatch(text.substring(0, 10));
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final parsed = DateTime(year, month, day);
    final real =
        parsed.year == year && parsed.month == month && parsed.day == day;
    return real ? parsed : null;
  }

  static final _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// The wall-clock parts of a time with no zone, to check that what was
  /// read is what was written.
  static final _wallClock = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?',
  );

  /// A moment, RFC 3339 with its offset, on the phone's clock.
  static DateTime? instant(dynamic value) {
    final text = nonEmpty(value);
    return text == null ? null : DateTime.tryParse(text)?.toLocal();
  }

  /// `2026-11-11 09:30:00`, Lao wall-clock time with no zone: read as that
  /// time on the phone's clock (09:30 stays 09:30), never as UTC. A value
  /// that does carry a zone is read as that moment instead.
  ///
  /// A time that does not exist (`25:99`, `24:00`, 30 February) is null,
  /// not rolled over.
  ///
  /// On a phone outside Laos this clock and [instant]'s are not the same:
  /// never compare or sort a wall-clock field against a moment.
  static DateTime? wallClock(dynamic value) {
    final text = nonEmpty(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    // With a zone it comes back as UTC: that moment, on the phone's clock.
    if (parsed.isUtc) return parsed.toLocal();

    // No zone: Dart reads it as local time already. Only keep it when it
    // is the time written, not one rolled over from an impossible value.
    final match = _wallClock.firstMatch(text);
    if (match == null) return null;
    final written = [
      for (var i = 1; i <= 6; i++) int.parse(match[i] ?? '0'),
    ];
    final read = [
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    ];
    for (var i = 0; i < 6; i++) {
      if (written[i] != read[i]) return null;
    }
    return parsed;
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
