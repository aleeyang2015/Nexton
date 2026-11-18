import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ot_draft.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';
import '../../domain/repositories/ot_repository.dart';
import '../datasources/ot_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class OtRepositoryImpl extends BaseRepository implements OtRepository {
  final OtRemoteDataSource _remote;

  OtRepositoryImpl({required OtRemoteDataSource remote}) : _remote = remote;

  @override
  FutureResult<OtRequest> ask(OtDraft draft) => guard(() => _remote.ask(draft));

  @override
  FutureResult<OtPage<OtRequest>> myRequests({
    OtStatus? status,
    DateTime? month,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => guard(
    () => _remote.myRequests(
      status: status,
      month: month,
      page: page,
      perPage: perPage,
    ),
  );

  @override
  FutureResult<OtPage<OtRequest>> myApprovals({
    required OtApprovalStatus status,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => guard(
    () => _remote.myApprovals(status: status, page: page, perPage: perPage),
  );

  @override
  FutureResult<OtRequest> request(String id) => guard(() => _remote.request(id));

  @override
  FutureResult<OtRequest> edit(String id, OtDraft draft) =>
      guard(() => _remote.edit(id, draft));

  @override
  FutureResult<OtRequest> cancel(String id) => guard(() => _remote.cancel(id));

  @override
  FutureResult<OtPage<OtPost>> openPosts({
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) =>
      guard(() => _remote.openPosts(page: page, perPage: perPage));

  @override
  FutureResult<OtRequest> join(String postId) =>
      guard(() => _remote.join(postId));
}
