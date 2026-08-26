import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/payslip.dart';
import '../../domain/repositories/salary_repository.dart';
import '../datasources/salary_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class SalaryRepositoryImpl extends BaseRepository implements SalaryRepository {
  final SalaryRemoteDataSource _remote;

  SalaryRepositoryImpl({required SalaryRemoteDataSource remote}) : _remote = remote;

  @override
  FutureResult<List<Payslip>> history(int year) => guard(() => _remote.history(year));
}
