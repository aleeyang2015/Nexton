import 'package:equatable/equatable.dart';

import 'leave_duration_type.dart';
import 'uploaded_attachment.dart';

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

  /// The file uploaded via the form's attachment slot, or null. Only emitted
  /// on the wire when non-null — on edit, omitting the key keeps the existing
  /// attachment (§3.4).
  final UploadedAttachment? attachment;

  const LeaveRequestDraft({
    required this.leaveTypeId,
    required this.dates,
    this.startDate,
    this.endDate,
    this.durationType = LeaveDurationType.fullDay,
    this.returnDate,
    this.reason = '',
    this.attachment,
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
    attachment,
  ];
}
