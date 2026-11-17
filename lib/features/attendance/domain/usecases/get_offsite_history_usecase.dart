import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/offsite_repository.dart';

/// The status picked and where to go on from: one page of "My requests".
typedef OffsiteHistoryPageParams = ({
  TimeCorrectionStatus? status,
  String? cursor,
});

/// One page of the off-site scan requests the employee has filed, newest
/// first, for "My requests" (#42). The status is a server filter, so each
/// picked status pages through its own list.
class GetOffsiteHistoryUseCase {
  final OffsiteRepository _repository;

  GetOffsiteHistoryUseCase(this._repository);

  FutureResult<CursorPage<OffsiteRequestDetail>> call(
    OffsiteHistoryPageParams params,
  ) => _repository.myRequests(status: params.status, cursor: params.cursor);
}
