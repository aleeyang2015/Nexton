import '../../domain/entities/leave_type.dart';
import 'leave_parse.dart';

/// Reads one row of `GET /leave/types` (leave-request-flutter.md §3.2).
class LeaveTypeModel {
  const LeaveTypeModel._();

  static LeaveType fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: LeaveJson.str(json['id']) ?? '',
      code: LeaveJson.str(json['code']) ?? '',
      name: LeaveJson.str(json['name']) ?? '',
      nameLo: LeaveJson.nonEmpty(json['name_lo']),
      color: LeaveJson.nonEmpty(json['color']),
      // Always sent; a list that predates the field reads as switched on.
      isActive: LeaveJson.boolOf(json['is_active'], fallback: true),
      maxDaysPerRequest: LeaveJson.doubleOf(json['max_days_per_request']),
      maxConsecutiveDays: LeaveJson.doubleOf(json['max_consecutive_days']),
      minNoticeDays: LeaveJson.intOf(json['min_notice_days']),
      allowHalfDay: LeaveJson.boolOf(json['allow_half_day']),
      requiresAttachment: LeaveJson.boolOf(json['requires_attachment']),
      allowNegativeBalance: LeaveJson.boolOf(json['allow_negative_balance']),
      isPaid: LeaveJson.boolOf(json['is_paid'], fallback: true),
    );
  }
}
