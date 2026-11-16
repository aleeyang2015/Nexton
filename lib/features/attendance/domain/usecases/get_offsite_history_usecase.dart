import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../repositories/offsite_repository.dart';

/// Loads the off-site scan requests the employee has filed, for the history
/// page that fronts the "ລົງເວລານອກພື້ນທີ່" menu.
///
/// No status parameter, unlike [GetOffsiteApprovalsUseCase]: on an employee's
/// own list the status is the request's own, so the page filters and counts the
/// one list it already holds.
class GetOffsiteHistoryUseCase
    implements NoParamsUseCase<List<OffsiteRequestDetail>> {
  final OffsiteRepository _repository;

  GetOffsiteHistoryUseCase(this._repository);

  @override
  FutureResult<List<OffsiteRequestDetail>> call() => _repository.mine();
}
