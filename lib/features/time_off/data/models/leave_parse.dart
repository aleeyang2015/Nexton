/// Shared JSON coercion helpers for the leave models — same tolerant style as
/// `AttendanceRecordModel`'s private helpers, lifted to a file because five
/// models need them.
class LeaveJson {
  LeaveJson._();

  static String? str(dynamic value) => value is String ? value : null;

  static String? nonEmpty(dynamic value) {
    final text = str(value);
    return (text == null || text.isEmpty) ? null : text;
  }

  static bool boolOf(dynamic value, {bool fallback = false}) =>
      value is bool ? value : fallback;

  static int? intOf(dynamic value) => (value as num?)?.toInt();

  static double? doubleOf(dynamic value) => (value as num?)?.toDouble();

  static double doubleOr(dynamic value, double fallback) =>
      doubleOf(value) ?? fallback;

  /// A `YYYY-MM-DD` (or full ISO) date. Kept in local time — these are
  /// calendar days, not instants, so no timezone shift.
  static DateTime? date(dynamic value) {
    final text = nonEmpty(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// An instant (`created_at` etc.): UTC in, local out.
  static DateTime? dateTime(dynamic value) {
    final text = nonEmpty(value);
    if (text == null) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static List<Map<String, dynamic>> objects(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
