import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/leave_remote_data_source.dart';
import 'data/repositories/leave_repository_impl.dart';
import 'domain/repositories/leave_repository.dart';
import 'domain/usecases/approve_leave_step_usecase.dart';
import 'domain/usecases/cancel_leave_request_usecase.dart';
import 'domain/usecases/get_leave_approvals_usecase.dart';
import 'domain/usecases/get_leave_balances_usecase.dart';
import 'domain/usecases/get_leave_history_usecase.dart';
import 'domain/usecases/get_leave_request_detail_usecase.dart';
import 'domain/usecases/get_leave_types_usecase.dart';
import 'domain/usecases/reject_leave_step_usecase.dart';
import 'domain/usecases/submit_leave_request_usecase.dart';
import 'domain/usecases/update_leave_request_usecase.dart';

/// Composition root for the time-off feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the datasource.
final leaveRemoteDataSourceProvider = Provider<LeaveRemoteDataSource>(
  (ref) => LeaveRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepositoryImpl(remote: ref.watch(leaveRemoteDataSourceProvider));
});

final getLeaveTypesUseCaseProvider = Provider<GetLeaveTypesUseCase>(
  (ref) => GetLeaveTypesUseCase(ref.watch(leaveRepositoryProvider)),
);

final getLeaveBalancesUseCaseProvider = Provider<GetLeaveBalancesUseCase>(
  (ref) => GetLeaveBalancesUseCase(ref.watch(leaveRepositoryProvider)),
);

final getLeaveHistoryUseCaseProvider = Provider<GetLeaveHistoryUseCase>(
  (ref) => GetLeaveHistoryUseCase(ref.watch(leaveRepositoryProvider)),
);

final getLeaveRequestDetailUseCaseProvider =
    Provider<GetLeaveRequestDetailUseCase>(
      (ref) => GetLeaveRequestDetailUseCase(ref.watch(leaveRepositoryProvider)),
    );

final submitLeaveRequestUseCaseProvider = Provider<SubmitLeaveRequestUseCase>(
  (ref) => SubmitLeaveRequestUseCase(ref.watch(leaveRepositoryProvider)),
);

final updateLeaveRequestUseCaseProvider = Provider<UpdateLeaveRequestUseCase>(
  (ref) => UpdateLeaveRequestUseCase(ref.watch(leaveRepositoryProvider)),
);

final cancelLeaveRequestUseCaseProvider = Provider<CancelLeaveRequestUseCase>(
  (ref) => CancelLeaveRequestUseCase(ref.watch(leaveRepositoryProvider)),
);

final getLeaveApprovalsUseCaseProvider = Provider<GetLeaveApprovalsUseCase>(
  (ref) => GetLeaveApprovalsUseCase(ref.watch(leaveRepositoryProvider)),
);

final approveLeaveStepUseCaseProvider = Provider<ApproveLeaveStepUseCase>(
  (ref) => ApproveLeaveStepUseCase(ref.watch(leaveRepositoryProvider)),
);

final rejectLeaveStepUseCaseProvider = Provider<RejectLeaveStepUseCase>(
  (ref) => RejectLeaveStepUseCase(ref.watch(leaveRepositoryProvider)),
);
