import 'package:equatable/equatable.dart';

/// How a company day off repeats (`GET /core_hr/rest-days`, the row's `type`).
enum RestDayType {
  /// Every week on one weekday. `value` is `MON` … `SUN`.
  weekly,

  /// Every month on one day of the month. `value` is `1` … `31`.
  monthly,

  /// Every year on one date. `value` is `MM-DD`.
  yearly,

  /// One date only. `value` is `YYYY-MM-DD`.
  custom,
}

/// One row of the company's days off: a kind of repetition and the value it
/// repeats on, as the backend stores it.
class RestDayRule extends Equatable {
  final RestDayType type;
  final String value;

  const RestDayRule({required this.type, required this.value});

  @override
  List<Object?> get props => [type, value];
}

/// The company's days off — the days nobody is expected to work, so a leave
/// that runs across one is not charged for it.
///
/// [isDayOff] applies the same four rules as the backend's `is_rest_day`, so
/// the calendar greys out exactly the days the server skips in a date range.
/// It covers the company's own rest days only. Public holidays are a separate
/// list and are not here.
///
/// What this gives the form is a preview: the server counts the days of a
/// request, and its answer is the truth.
class CompanyDaysOff extends Equatable {
  final List<RestDayRule> rules;

  const CompanyDaysOff(this.rules);

  /// A company with no days off at all: every day is a working day.
  static const none = CompanyDaysOff([]);

  /// `weekly` values by `DateTime.weekday` (1 = Monday … 7 = Sunday). Matched
  /// by number, never by a weekday's name in some language.
  static const List<String> _weekdayCodes = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  /// True when [day] is one of the company's days off.
  bool isDayOff(DateTime day) {
    for (final rule in rules) {
      if (_matches(rule, day)) return true;
    }
    return false;
  }

  /// The days from [start] to [end], both included, that are not days off —
  /// the days a date-range request is charged for. Empty when [end] is before
  /// [start] or every day in between is a day off.
  List<DateTime> workingDaysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    // Calendar steps, not 24-hour ones: a day is not always 24 hours long.
    for (
      var day = DateTime(start.year, start.month, start.day);
      !day.isAfter(DateTime(end.year, end.month, end.day));
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      if (!isDayOff(day)) days.add(day);
    }
    return days;
  }

  /// The first day after [day] that is not a day off: when someone on leave
  /// until [day] is back at work.
  ///
  /// A company whose rules leave no working day at all (every weekday off)
  /// has no such day; the day after [day] is returned rather than looping
  /// for ever.
  DateTime firstWorkingDayAfter(DateTime day) {
    for (var offset = 1; offset <= _searchLimitDays; offset++) {
      final candidate = DateTime(day.year, day.month, day.day + offset);
      if (!isDayOff(candidate)) return candidate;
    }
    return DateTime(day.year, day.month, day.day + 1);
  }

  /// Longer than any real run of days off; only an all-week rule reaches it.
  static const int _searchLimitDays = 366;

  static bool _matches(RestDayRule rule, DateTime day) {
    final value = rule.value.trim();

    switch (rule.type) {
      case RestDayType.weekly:
        return value.toUpperCase() == _weekdayCodes[day.weekday - 1];

      case RestDayType.monthly:
        // `int.tryParse` reads "08" as 8, as the backend does.
        return int.tryParse(value) == day.day;

      case RestDayType.yearly:
        final parts = value.split('-');
        if (parts.length != 2) return false;
        return int.tryParse(parts[0]) == day.month &&
            int.tryParse(parts[1]) == day.day;

      case RestDayType.custom:
        final parts = value.split('-');
        if (parts.length != 3) return false;
        return int.tryParse(parts[0]) == day.year &&
            int.tryParse(parts[1]) == day.month &&
            int.tryParse(parts[2]) == day.day;
    }
  }

  @override
  List<Object?> get props => [rules];
}
