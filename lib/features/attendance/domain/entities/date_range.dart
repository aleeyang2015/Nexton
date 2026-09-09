import 'package:equatable/equatable.dart';

/// An inclusive `start`–`end` date span. Both `records/my` (§6.2) and
/// `records/summary/my` (§6.3) read it as a single `month` (`start`'s year
/// and month — every caller builds this via [DateRange.month], so a whole
/// calendar month is always what's in it).
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// The calendar month [date] falls in, from its 1st to its last day.
  factory DateRange.month(DateTime date) {
    final firstDay = DateTime(date.year, date.month);
    final firstOfNextMonth = DateTime(date.year, date.month + 1);
    final lastDay = firstOfNextMonth.subtract(const Duration(days: 1));
    return DateRange(start: firstDay, end: lastDay);
  }

  @override
  List<Object?> get props => [start, end];
}
