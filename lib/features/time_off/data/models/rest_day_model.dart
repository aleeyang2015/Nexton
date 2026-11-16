import '../../domain/entities/company_days_off.dart';
import 'leave_parse.dart';

/// Reads one row of `GET /core_hr/rest-days`: `type` (`weekly`, `monthly`,
/// `yearly`, `custom`) and `value`.
class RestDayModel {
  const RestDayModel._();

  /// The rule, or null for a row the app cannot use: a `type` it does not
  /// know, or no `value`. Such a row is left out rather than guessed at; the
  /// server still skips that day in a date range.
  static RestDayRule? fromJson(Map<String, dynamic> json) {
    final type = switch (LeaveJson.str(json['type'])) {
      'weekly' => RestDayType.weekly,
      'monthly' => RestDayType.monthly,
      'yearly' => RestDayType.yearly,
      'custom' => RestDayType.custom,
      _ => null,
    };
    final value = _value(json['value']);
    if (type == null || value == null) return null;

    return RestDayRule(type: type, value: value);
  }

  /// A monthly value may arrive as a number.
  static String? _value(dynamic value) {
    if (value is num) return value.toInt().toString();
    final text = LeaveJson.str(value)?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
