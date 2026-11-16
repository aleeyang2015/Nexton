import 'package:equatable/equatable.dart';

import 'leave_duration_type.dart';
import 'uploaded_attachment.dart';

/// What the request-leave form submits (`POST`/`PUT /leave/requests`,
/// leave-request-flutter.md §3.3/§3.4).
///
/// Leave days are picked individually via [dates] (not a start/end range) —
/// `total_days` is simply their count, or `0.5` when [durationType] is a
/// half-day (which requires exactly one date).
class LeaveRequestDraft extends Equatable {
  final String leaveTypeId;
  final List<DateTime> dates;
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
    this.durationType = LeaveDurationType.fullDay,
    this.returnDate,
    this.reason = '',
    this.attachment,
  });

  double get totalDays =>
      durationType.isHalfDay ? 0.5 : dates.length.toDouble();

  @override
  List<Object?> get props => [
    leaveTypeId,
    dates,
    durationType,
    returnDate,
    reason,
    attachment,
  ];
}
