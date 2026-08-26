import 'package:equatable/equatable.dart';

import 'leave_category.dart';
import 'leave_status.dart';

/// One subordinate's leave request as seen from the approver's side: who
/// asked, for what and why, and where it stands. [isNew] drives the "ໃໝ່"
/// badge on a still-pending item — it has no meaning once decided.
class LeaveApproval extends Equatable {
  final String id;
  final String requesterName;
  final LeaveCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final bool isNew;

  const LeaveApproval({
    required this.id,
    required this.requesterName,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.isNew = false,
  });

  @override
  List<Object?> get props => [
    id,
    requesterName,
    category,
    startDate,
    endDate,
    totalDays,
    reason,
    status,
    isNew,
  ];
}
