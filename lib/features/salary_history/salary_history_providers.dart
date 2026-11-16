import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/salary_remote_data_source.dart';
import 'data/repositories/salary_repository_impl.dart';
import 'domain/repositories/salary_repository.dart';
import 'domain/usecases/download_payslip_pdf_usecase.dart';
import 'domain/usecases/get_payslip_detail_usecase.dart';
import 'domain/usecases/get_payslip_history_usecase.dart';

/// Composition root for the salary-history feature: the one place the data
/// layer is constructed and bound to the domain contracts. Presentation
/// consumes only the use case providers, never the datasource.
final salaryRemoteDataSourceProvider = Provider<SalaryRemoteDataSource>(
  (ref) => SalaryRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  return SalaryRepositoryImpl(remote: ref.watch(salaryRemoteDataSourceProvider));
});

final getPayslipHistoryUseCaseProvider = Provider<GetPayslipHistoryUseCase>((ref) {
  return GetPayslipHistoryUseCase(ref.watch(salaryRepositoryProvider));
});

final getPayslipDetailUseCaseProvider = Provider<GetPayslipDetailUseCase>((ref) {
  return GetPayslipDetailUseCase(ref.watch(salaryRepositoryProvider));
});

final downloadPayslipPdfUseCaseProvider = Provider<DownloadPayslipPdfUseCase>((ref) {
  return DownloadPayslipPdfUseCase(ref.watch(salaryRepositoryProvider));
});
