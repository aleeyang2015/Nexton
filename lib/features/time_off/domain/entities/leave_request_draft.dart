import 'package:equatable/equatable.dart';

import 'leave_category.dart';

/// What the request-leave form submits: specific leave days (not
/// necessarily contiguous) rather than a start/end range, plus when the
/// employee returns to work.
class LeaveRequestDraft extends Equatable {
  final LeaveCategory category;
  final List<DateTime> dates;
  final DateTime returnToWorkDate;
  final String reason;

  const LeaveRequestDraft({
    required this.category,
    required this.dates,
    required this.returnToWorkDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [category, dates, returnToWorkDate, reason];
}
