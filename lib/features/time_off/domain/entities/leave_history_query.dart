import 'package:equatable/equatable.dart';

import 'leave_category.dart';

/// Filter for the history tab's list — a `null` [category] means "all".
class LeaveHistoryQuery extends Equatable {
  final LeaveCategory? category;
  final DateTime from;
  final DateTime to;

  const LeaveHistoryQuery({
    this.category,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [category, from, to];
}
