import 'package:equatable/equatable.dart';

/// One row of `GET /leave/types` (leave-request-flutter.md §3.2) — the leave
/// categories the history filter, the request form and the balance card all
/// key off of. Replaces the old fixed `LeaveCategory` enum: the request POST
/// needs a real `leave_type_id` UUID, so the list has to come from the API.
///
/// [name]/[nameLo] are shown as-is; `LeaveCopy` picks the one that matches the
/// active locale. The `*PerRequest` / `minNoticeDays` limits and the boolean
/// flags drive what the form allows before a round trip.
class LeaveType extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? nameLo;
  final String? color;
  final int? maxDaysPerRequest;
  final int? maxConsecutiveDays;
  final int? minNoticeDays;
  final bool allowHalfDay;
  final bool requiresAttachment;
  final bool allowNegativeBalance;
  final bool isPaid;

  const LeaveType({
    required this.id,
    required this.code,
    required this.name,
    this.nameLo,
    this.color,
    this.maxDaysPerRequest,
    this.maxConsecutiveDays,
    this.minNoticeDays,
    this.allowHalfDay = false,
    this.requiresAttachment = false,
    this.allowNegativeBalance = false,
    this.isPaid = true,
  });

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    nameLo,
    color,
    maxDaysPerRequest,
    maxConsecutiveDays,
    minNoticeDays,
    allowHalfDay,
    requiresAttachment,
    allowNegativeBalance,
    isPaid,
  ];
}
