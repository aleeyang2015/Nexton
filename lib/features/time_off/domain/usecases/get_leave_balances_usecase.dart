import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_balance.dart';
import '../repositories/leave_repository.dart';

/// Loads the per-type quota rollup for a year (`GET /leave/balances/my`).
class GetLeaveBalancesUseCase implements BaseUseCase<List<LeaveBalance>, int> {
  final LeaveRepository _repository;

  GetLeaveBalancesUseCase(this._repository);

  @override
  FutureResult<List<LeaveBalance>> call(int year) => _repository.balances(year);
}
