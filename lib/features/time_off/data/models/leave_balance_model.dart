import '../../domain/entities/leave_balance.dart';
import 'leave_parse.dart';

/// Reads one row of `GET /leave/balances/my` (leave-request-flutter.md §3.1).
class LeaveBalanceModel {
  const LeaveBalanceModel._();

  static LeaveBalance fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveTypeId: LeaveJson.str(json['leave_type_id']) ?? '',
      leaveTypeName: LeaveJson.str(json['leave_type_name']) ?? '',
      leaveTypeCode: LeaveJson.nonEmpty(json['leave_type_code']),
      year: LeaveJson.intOf(json['year']) ?? DateTime.now().year,
      totalDays: LeaveJson.doubleOr(json['total_days'], 0),
      usedDays: LeaveJson.doubleOr(json['used_days'], 0),
      pendingDays: LeaveJson.doubleOr(json['pending_days'], 0),
      remainingDays: LeaveJson.doubleOr(json['remaining_days'], 0),
      carriedForwardDays: LeaveJson.doubleOr(json['carried_forward_days'], 0),
    );
  }
}
