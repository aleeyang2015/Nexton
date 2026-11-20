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

  /// False once HR has switched the type off. It is still in the list, so an
  /// old request can be named, but the form no longer offers it.
  final bool isActive;

  /// Decimals on the wire: a type can allow 2.5 days. Null, 0 or below means
  /// no limit, as on the server (#104); a stored 0 is sent as `0`.
  final double? maxDaysPerRequest;

  /// Not used by the form yet. When it is, read null, 0 or below as no
  /// limit, the same as [maxDaysPerRequest] (#104).
  final double? maxConsecutiveDays;
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
    this.isActive = true,
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
    isActive,
    maxDaysPerRequest,
    maxConsecutiveDays,
    minNoticeDays,
    allowHalfDay,
    requiresAttachment,
    allowNegativeBalance,
    isPaid,
  ];
}
