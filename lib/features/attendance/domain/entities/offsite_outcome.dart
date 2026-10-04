import 'package:equatable/equatable.dart';

import 'punch_outcome.dart';

/// An off-site scan request the backend accepted (§3's `201 Created`).
///
/// Only the fields the form has something to say about are kept. A POST can
/// answer with just two of the four documented statuses — `approved` when the
/// employee holds `can_work_offsite`, `pending` otherwise — so this carries
/// that one distinction rather than the whole status vocabulary, which belongs
/// to the request list and its detail view.
class OffsiteSubmission extends Equatable {
  /// `status == "approved"`: nobody has to approve it and the punch is already
  /// written. The employee is told their scan counted, not that it was filed.
  final bool autoApproved;

  /// When the server stamped the scan — tenant-local wall clock, so it is held
  /// exactly as read with no timezone shift (§11.4).
  final DateTime? scanTimestamp;

  /// Which shift segment of the day the scan landed in.
  final int? sessionOrder;

  /// Set once the punch exists; null while the request waits for HR.
  final String? attendanceRecordId;

  /// The `status` as sent, so a value added server-side still reaches a log.
  final String rawStatus;

  const OffsiteSubmission({
    required this.autoApproved,
    this.scanTimestamp,
    this.sessionOrder,
    this.attendanceRecordId,
    this.rawStatus = '',
  });

  @override
  List<Object?> get props => [
    autoApproved,
    scanTimestamp,
    sessionOrder,
    attendanceRecordId,
    rawStatus,
  ];
}

/// The result of filing an off-site scan request the server answered
/// definitively.
///
/// Same split as [PunchOutcome], and for the same reason: §3's 409s are the
/// session rules talking ("you already clocked in for the morning"), not a
/// failed request, and §11.4 is explicit that they must not be shown as a red
/// crash. Transport, auth and 5xx errors stay in `Result.failure`.
sealed class OffsiteOutcome {
  const OffsiteOutcome();
}

/// The request was created — auto-approved, or waiting for HR.
class OffsiteFiled extends OffsiteOutcome with EquatableMixin {
  final OffsiteSubmission submission;

  const OffsiteFiled(this.submission);

  @override
  List<Object?> get props => [submission];
}

/// A session rule refused the scan. [rule] is the same vocabulary a punch is
/// refused with — the off-site endpoint is gated by the same guard — plus the
/// two refusals only it can raise.
class OffsiteBlocked extends OffsiteOutcome with EquatableMixin {
  final AttendanceRule rule;

  /// The backend's wording, already tailored to the situation and preferred
  /// over anything the app could invent (§5, §7 rule 7).
  final String message;

  final PunchBlockDetails details;

  const OffsiteBlocked({
    required this.rule,
    required this.message,
    this.details = PunchBlockDetails.empty,
  });

  @override
  List<Object?> get props => [rule, message, details];
}
