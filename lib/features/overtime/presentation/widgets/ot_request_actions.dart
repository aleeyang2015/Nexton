import '../../domain/entities/ot_request.dart';
import '../../domain/entities/ot_step.dart';

/// What the request page offers its own employee: Edit, Cancel, or, once
/// approved, the line that says to ask the approver or HR.
///
/// These decide only which buttons show. The server still decides, and its
/// refusal is shown. Nothing shows on someone else's request (a head
/// opening a team member's), nor when the user's own employee id is not
/// known.
class OtRequestActions {
  /// While it waits, before any step is approved, and not for a join of an
  /// HR post (its time is HR's).
  final bool canEdit;

  /// While it waits (joins too).
  final bool canCancel;

  /// Approved: no buttons, but say whom to ask.
  final bool askApprover;

  const OtRequestActions._({
    required this.canEdit,
    required this.canCancel,
    required this.askApprover,
  });

  static const none = OtRequestActions._(
    canEdit: false,
    canCancel: false,
    askApprover: false,
  );

  factory OtRequestActions.of(
    OtRequest request, {
    required String? ownEmployeeId,
  }) {
    final mine =
        ownEmployeeId != null &&
        ownEmployeeId.isNotEmpty &&
        request.employeeId == ownEmployeeId;
    if (!mine) return none;

    final pending = request.status == OtStatus.pending;
    final anyApproved = request.steps.any(
      (step) => step.status == OtStepStatus.approved,
    );
    return OtRequestActions._(
      canEdit: pending && !anyApproved && request.announcementId == null,
      canCancel: pending,
      askApprover: request.status == OtStatus.approved,
    );
  }

  /// True when there is a button to show.
  bool get any => canEdit || canCancel;
}
