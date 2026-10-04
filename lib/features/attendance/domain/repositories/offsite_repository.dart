import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../entities/offsite_outcome.dart';
import '../entities/offsite_request.dart';
import '../entities/time_correction_status.dart';

/// Contract for the off-site scan requests ("ສະແກນນອກພື້ນທີ່").
///
/// Kept apart from `AttendanceRepository` rather than added to it: the two
/// speak to different endpoint groups, and §2's seven off-site routes would
/// otherwise double that contract's size for a workflow nothing else in
/// attendance calls. The composition root binds both.
abstract class OffsiteRepository {
  /// `POST /attendance/offsite-requests` — files a scan taken outside every
  /// geofence.
  ///
  /// Answers an [OffsiteOutcome] rather than throwing on a refusal, for the
  /// same reason the punch methods do: a 409 here is the session guard giving
  /// a definite answer ("you already clocked in"), not a failed request. Only
  /// transport, auth and server errors come back as `Result.failure`.
  FutureResult<OffsiteOutcome> submit(OffsiteRequest request);

  /// `GET /attendance/offsite-requests/my-approvals` — the requests the
  /// signed-in approver decides on, newest first.
  ///
  /// [status] is the endpoint's own filter, read against the caller's step
  /// (§5): `pending` is what still waits on them, `approved`/`rejected` what
  /// they have already decided. An HR user also sees what waits on the HR step.
  FutureResult<List<OffsiteRequestDetail>> approvals({
    TimeCorrectionStatus? status,
  });

  /// `PUT /attendance/offsite-requests/:id/approve` — [stepId] is the step the
  /// caller saw pending, so a decision aimed at a step that has since moved on
  /// is refused rather than applied to the wrong one (§7).
  ///
  /// The final approval is what writes the punch, so this call can still be
  /// refused by a session rule (`TOO_EARLY_CHECKIN`) after the decision itself
  /// was fine — the backend rolls the approval back when that happens.
  FutureResult<Unit> approve(String id, {String? stepId});

  /// `PUT /attendance/offsite-requests/:id/reject` — [note] is required by the
  /// endpoint (§8), and is what the employee is told.
  FutureResult<Unit> reject(
    String id, {
    required String note,
    String? stepId,
  });
}
