import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_summary.dart';
import '../repositories/leave_repository.dart';

/// Loads the annual summary tab's entitlement/used/remaining rollup.
class GetLeaveSummaryUseCase implements BaseUseCase<LeaveSummary, int> {
  final LeaveRepository _repository;

  GetLeaveSummaryUseCase(this._repository);

  @override
  FutureResult<LeaveSummary> call(int year) => _repository.summary(year);
}
