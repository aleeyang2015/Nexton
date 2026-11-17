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
    int perPage = 20,
  });

  /// One OT request; `404` when it is gone or not the caller's to see.
  FutureResult<OtRequest> request(String id);

  /// Changes a waiting OT request's day, times or reason.
  FutureResult<OtRequest> edit(String id, OtDraft draft);

  /// Cancels an OT request.
  FutureResult<OtRequest> cancel(String id);

  /// HR's open posts for the caller's department, one page at a time.
  FutureResult<OtPage<OtPost>> openPosts({int page = 1, int perPage = 20});

  /// Joins an HR post; the answer is the caller's new OT request.
  FutureResult<OtRequest> join(String postId);
}
