import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/offsite_outcome.dart';
import '../../domain/entities/offsite_request.dart';
import '../../domain/entities/time_correction_status.dart';
import '../../domain/repositories/offsite_repository.dart';
import '../datasources/offsite_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
///
/// No caching, for the same reason `AttendanceRepositoryImpl` has none: a
/// filed request becomes a punch, and a punch must never be replayed from
/// memory. Every call goes to the network, where §3's duplicate guard
/// (`OFFSITE_REQUEST_EXISTS`) is the single source of truth.
class OffsiteRepositoryImpl extends BaseRepository
    implements OffsiteRepository {
  final OffsiteRemoteDataSource _remote;

  OffsiteRepositoryImpl({required OffsiteRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<OffsiteOutcome> submit(OffsiteRequest request) =>
      guard(() => _remote.submit(request));

  @override
  FutureResult<List<OffsiteRequestDetail>> mine() => guard(_remote.mine);

  @override
  FutureResult<List<OffsiteRequestDetail>> approvals({
    TimeCorrectionStatus? status,
  }) => guard(() => _remote.approvals(status: status));

  @override
  FutureResult<Unit> approve(String id, {String? stepId}) => guard(() async {
    await _remote.approve(id, stepId: stepId);
    return Unit.instance;
  });

  @override
  FutureResult<Unit> reject(
    String id, {
    required String note,
    String? stepId,
  }) => guard(() async {
    await _remote.reject(id, note: note, stepId: stepId);
    return Unit.instance;
  });

  @override
  FutureResult<Unit> cancel(String id) => guard(() async {
    await _remote.cancel(id);
    return Unit.instance;
  });
}
