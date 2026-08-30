import 'package:equatable/equatable.dart';

import 'leave_status.dart';

/// Filter for `GET /leave/requests/my` (leave-request-flutter.md §3.6).
///
/// A `null` [leaveTypeId] or [status] means "all"; [from]/[to] map to the
/// endpoint's `start_date` / `end_date` query params.
class LeaveHistoryQuery extends Equatable {
  final String? leaveTypeId;
  final LeaveStatus? status;
  final DateTime from;
  final DateTime to;

  const LeaveHistoryQuery({
    this.leaveTypeId,
    this.status,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [leaveTypeId, status, from, to];
}
