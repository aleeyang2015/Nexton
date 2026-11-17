import 'package:equatable/equatable.dart';

/// What the user fills in to ask for OT, or to change one: the day it
/// starts, the company's `HH:MM` start and end, and a reason. How it is
/// sent is #28's.
class OtDraft extends Equatable {
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String? reason;

  const OtDraft({
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  @override
  List<Object?> get props => [workDate, startTime, endTime, reason];
}
