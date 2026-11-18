import '../../../../core/utils/result.dart';
import '../entities/ot_draft.dart';
import '../entities/ot_page.dart';
import '../entities/ot_post.dart';
import '../entities/ot_request.dart';

/// The employee's OT calls, as the presentation layer sees them. The
/// implementation lives in data/repositories.
abstract class OtRepository {
  /// Asks for OT. A refusal is a `Failure.validation` whose message is an
  /// `OtErrorCode` token.
  FutureResult<OtRequest> ask(OtDraft draft);

  /// The caller's OT requests, one page at a time, newest first as the
  /// server sends them. [status] null is all; [month] null is every month.
  FutureResult<OtPage<OtRequest>> myRequests({
    OtStatus? status,
    DateTime? month,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  });

  /// One page of the OT requests at the caller's approval steps (#48), by
  /// number. [status] is read against the caller's own step.
  FutureResult<OtPage<OtRequest>> myApprovals({
    required OtApprovalStatus status,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  });

  /// One OT request; `404` when it is gone or not the caller's to see.
  FutureResult<OtRequest> request(String id);

  /// Changes a waiting OT request's day, times or reason.
  FutureResult<OtRequest> edit(String id, OtDraft draft);

  /// Cancels an OT request: the employee's own waiting one (#32), or a
  /// head's approved one before it starts (#49).
  FutureResult<OtRequest> cancel(String id);

  /// A head approves / rejects the waiting step (#49). See the data source.
  FutureResult<OtRequest> approve(
    String id, {
    required String stepId,
    String? comment,
  });
  FutureResult<OtRequest> reject(
    String id, {
    required String stepId,
    required String comment,
  });

  /// HR's open posts for the caller's department, one page at a time.
  FutureResult<OtPage<OtPost>> openPosts({
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  });

  /// Joins an HR post; the answer is the caller's new OT request.
  FutureResult<OtRequest> join(String postId);
}
