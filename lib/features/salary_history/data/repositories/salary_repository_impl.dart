import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/payslip_pdf.dart';
import '../../domain/entities/payslip_record.dart';
import '../../domain/repositories/salary_repository.dart';
import '../datasources/salary_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class SalaryRepositoryImpl extends BaseRepository implements SalaryRepository {
  final SalaryRemoteDataSource _remote;

  SalaryRepositoryImpl({required SalaryRemoteDataSource remote}) : _remote = remote;

  @override
  FutureResult<PayslipPdf> pdf(String id) => guard(() => _remote.pdf(id));

  @override
  FutureResult<List<PayslipRecord>> myPayslips(int year) =>
      guard(() => _remote.myPayslips(year));

  @override
  FutureResult<PayslipRecord> myPayslip(String id) =>
      guard(() => _remote.myPayslip(id));

  @override
  FutureResult<PayslipLatest?> myLatestPayslip() =>
      guard(_remote.myLatestPayslip);
}
