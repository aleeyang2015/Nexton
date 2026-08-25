import 'package:equatable/equatable.dart';

/// An inclusive `start`–`end` date span, for the endpoints that take
/// `start_date`/`end_date` query params (§6.2, §6.3).
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
