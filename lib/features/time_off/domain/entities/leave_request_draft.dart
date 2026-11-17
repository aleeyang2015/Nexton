import 'package:equatable/equatable.dart';

import 'leave_duration_type.dart';
import 'leave_attachment.dart';

/// What the request-leave form submits (`POST`/`PUT /leave/requests`,
/// leave-request-flutter.md §3.3/§3.4).
///
/// The leave days are given in one of two ways, never both:
///
/// * [dates] — days picked one by one. Every day sent is charged.
/// * [startDate] and [endDate] — a range, with [dates] empty. The server
///   leaves the company's days off out of it and charges the rest.
///
/// A half-day [durationType] is exactly one date in [dates].
class LeaveRequestDraft extends Equatable {
  final String leaveTypeId;
  final List<DateTime> dates;

  /// The range's first and last day, both included; null for separate days.
  final DateTime? startDate;
  final DateTime? endDate;
  final LeaveDurationType durationType;
  final DateTime? returnDate;
  final String reason;

  /// The request's files, when they are to be sent: on a create, those
  /// attached; on an edit, the whole new list (kept and new), and only when
  /// the user changed the files. Null leaves them alone: on an edit the
  /// server keeps the files it has (`attachments` absent), while `[]`
  /// would remove them all.
  final List<LeaveAttachment>? attachments;

  const LeaveRequestDraft({
    required this.leaveTypeId,
    required this.dates,
    this.startDate,
    this.endDate,
    this.durationType = LeaveDurationType.fullDay,
    this.returnDate,
    this.reason = '',
    this.attachments,
  });

  /// True when the days are a range rather than a list of days.
  bool get isRange => startDate != null && endDate != null;

  @override
  List<Object?> get props => [
    leaveTypeId,
    dates,
    startDate,
    endDate,
    durationType,
    returnDate,
    reason,
    attachments,
  ];
}
