import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/leave_remote_data_source.dart';
import 'data/repositories/leave_repository_impl.dart';
import 'domain/repositories/leave_repository.dart';
import 'domain/usecases/decide_approval_usecase.dart';
import 'domain/usecases/get_approval_history_usecase.dart';
import 'domain/usecases/get_leave_history_usecase.dart';
import 'domain/usecases/get_leave_summary_usecase.dart';
import 'domain/usecases/get_pending_approvals_usecase.dart';
import 'domain/usecases/submit_leave_request_usecase.dart';

/// Composition root for the time-off feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the datasource.
final leaveRemoteDataSourceProvider = Provider<LeaveRemoteDataSource>(
  (ref) => LeaveRemoteDataSourceImpl(),
);

/// Exposed as the abstract type so consumers never see the impl.
final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepositoryImpl(remote: ref.watch(leaveRemoteDataSourceProvider));
});

final getLeaveHistoryUseCaseProvider = Provider<GetLeaveHistoryUseCase>((ref) {
  return GetLeaveHistoryUseCase(ref.watch(leaveRepositoryProvider));
});

final getLeaveSummaryUseCaseProvider = Provider<GetLeaveSummaryUseCase>((ref) {
  return GetLeaveSummaryUseCase(ref.watch(leaveRepositoryProvider));
});

final submitLeaveRequestUseCaseProvider = Provider<SubmitLeaveRequestUseCase>((
  ref,
) {
  return SubmitLeaveRequestUseCase(ref.watch(leaveRepositoryProvider));
});

final getPendingApprovalsUseCaseProvider = Provider<GetPendingApprovalsUseCase>(
  (ref) => GetPendingApprovalsUseCase(ref.watch(leaveRepositoryProvider)),
);

final getApprovalHistoryUseCaseProvider = Provider<GetApprovalHistoryUseCase>(
  (ref) => GetApprovalHistoryUseCase(ref.watch(leaveRepositoryProvider)),
);

final decideApprovalUseCaseProvider = Provider<DecideApprovalUseCase>(
  (ref) => DecideApprovalUseCase(ref.watch(leaveRepositoryProvider)),
);
