import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/salary_remote_data_source.dart';
import 'data/repositories/salary_repository_impl.dart';
import 'domain/repositories/salary_repository.dart';
import 'domain/usecases/get_payslip_history_usecase.dart';

/// Composition root for the salary-history feature: the one place the data
/// layer is constructed and bound to the domain contracts. Presentation
/// consumes only the use case provider, never the datasource.
final salaryRemoteDataSourceProvider = Provider<SalaryRemoteDataSource>(
  (ref) => SalaryRemoteDataSourceImpl(),
);

/// Exposed as the abstract type so consumers never see the impl.
final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  return SalaryRepositoryImpl(remote: ref.watch(salaryRemoteDataSourceProvider));
});

final getPayslipHistoryUseCaseProvider = Provider<GetPayslipHistoryUseCase>((ref) {
  return GetPayslipHistoryUseCase(ref.watch(salaryRepositoryProvider));
});
