import 'package:equatable/equatable.dart';

/// One leave type's quota for a year, from `GET /leave/balances/my`
/// (leave-request-flutter.md §3.1).
///
/// [remainingDays] is what the employee can still request (the form validates
/// against it before submitting); the backend reserves days into
/// [pendingDays] the moment a request is submitted and moves them to
/// [usedDays] once every approval step passes.
class LeaveBalance extends Equatable {
  final String leaveTypeId;
  final String leaveTypeName;
  final String? leaveTypeCode;
  final int year;
  final double totalDays;
  final double usedDays;
  final double pendingDays;
  final double remainingDays;
  final double carriedForwardDays;

  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    this.leaveTypeCode,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.pendingDays,
    required this.remainingDays,
    this.carriedForwardDays = 0,
  });

  @override
  List<Object?> get props => [
    leaveTypeId,
    leaveTypeName,
    leaveTypeCode,
    year,
    totalDays,
    usedDays,
    pendingDays,
    remainingDays,
    carriedForwardDays,
  ];
}
