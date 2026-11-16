import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../entities/time_correction_status.dart';
import '../repositories/offsite_repository.dart';

/// Loads one status bucket of the off-site scan requests the signed-in approver
/// is involved in, for the approvals page's off-site tab.
///
/// The status is the endpoint's own filter, not a local one: it is read against
/// the caller's step, so `pending` means "still waiting on you".
class GetOffsiteApprovalsUseCase
    implements BaseUseCase<List<OffsiteRequestDetail>, TimeCorrectionStatus?> {
  final OffsiteRepository _repository;

  GetOffsiteApprovalsUseCase(this._repository);

  @override
  FutureResult<List<OffsiteRequestDetail>> call(TimeCorrectionStatus? status) =>
      _repository.approvals(status: status);
}
