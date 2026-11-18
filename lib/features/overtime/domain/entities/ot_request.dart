import 'package:equatable/equatable.dart';

import 'ot_piece.dart';
import 'ot_step.dart';

/// Where an OT request stands. A value the App does not know is [unknown],
/// never read as one of the others.
enum OtStatus { pending, approved, rejected, cancelled, unknown }

/// The approver's lists of OT requests (#48), read against their own step:
/// [pending] waits on them, [approved] / [rejected] they decided. Its
/// [name] is the wire value.
enum OtApprovalStatus { pending, approved, rejected }

/// One OT request (`OTRequestResponse`): the same shape from the list, the
/// detail, ask, edit, join, approve, reject and cancel.
///
/// Times come in two kinds. [workDate] is a calendar day (the day the OT
/// starts); [startTime] and [endTime] are the company's `HH:MM`, shown as
/// sent. [startsAt] and [endsAt] are moments; [createdAt], [updatedAt] and
/// [paidByHandAt] are Lao wall-clock times. All are on the phone's clock,
/// but on a phone outside Laos the two kinds are not on the same clock:
/// never compare or sort a wall-clock field against a moment.
///
/// The employee's department is their current one (#48: the server fills
/// `employee.department` since 15 Nov). Who paid by hand is a user id and is
/// not kept.
class OtRequest extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeNumber;

  /// The employee's department now, in English and Lao; null when they have
  /// none.
  final String? departmentName;
  final String? departmentNameLo;

  /// Set when this request joined an HR post.
  final String? announcementId;

  /// Null only when the server sent something that is not a day.
  final DateTime? workDate;
  final String startTime;
  final String endTime;
  final bool endsNextDay;
  final DateTime? startsAt;
  final DateTime? endsAt;

  final String? reason;
  final String? agreementNote;
  final OtStatus status;
  final int currentStepNo;
  final bool hrOnly;
  final bool didNotCome;
  final DateTime? paidByHandAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<OtStep> steps;

  /// Empty until HR approves.
  final List<OtPiece> pieces;

  const OtRequest({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeNumber,
    this.departmentName,
    this.departmentNameLo,
    this.announcementId,
    this.workDate,
    required this.startTime,
    required this.endTime,
    this.endsNextDay = false,
    this.startsAt,
    this.endsAt,
    this.reason,
    this.agreementNote,
    required this.status,
    this.currentStepNo = 0,
    this.hrOnly = false,
    this.didNotCome = false,
    this.paidByHandAt,
    this.createdAt,
    this.updatedAt,
    this.steps = const [],
    this.pieces = const [],
  });

  /// The step waiting for a decision now, or null when none is.
  OtStep? get pendingStep {
    for (final step in steps) {
      if (step.status == OtStepStatus.pending) return step;
    }
    return null;
  }

  /// True once any step has been approved.
  bool get hasApprovedStep =>
      steps.any((step) => step.status == OtStepStatus.approved);

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    employeeNumber,
    departmentName,
    departmentNameLo,
    announcementId,
    workDate,
    startTime,
    endTime,
    endsNextDay,
    startsAt,
    endsAt,
    reason,
    agreementNote,
    status,
    currentStepNo,
    hrOnly,
    didNotCome,
    paidByHandAt,
    createdAt,
    updatedAt,
    steps,
    pieces,
  ];
}
