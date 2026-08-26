import 'package:equatable/equatable.dart';

import 'leave_category.dart';
import 'leave_status.dart';

/// One submitted leave request and where it stands in the approval chain.
///
/// The chain is always submit → manager review → HR approval; a rejection is
/// assumed to happen at the manager step, since that's the only rejection
/// case the product has specified so far.
class LeaveRequest extends Equatable {
  final String id;
  final LeaveCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final LeaveStatus status;
  final String? reviewerComment;

  const LeaveRequest({
    required this.id,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    this.reviewerComment,
  });

  @override
  List<Object?> get props => [
    id,
    category,
    startDate,
    endDate,
    totalDays,
    status,
    reviewerComment,
  ];
}
