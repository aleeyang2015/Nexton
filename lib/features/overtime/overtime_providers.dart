import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import '../auth/presentation/providers/auth_session_notifier.dart';
import 'data/datasources/ot_remote_data_source.dart';
import 'data/repositories/ot_repository_impl.dart';
import 'domain/repositories/ot_repository.dart';
import 'domain/usecases/ask_ot_usecase.dart';
import 'domain/usecases/cancel_ot_usecase.dart';
import 'domain/usecases/edit_ot_usecase.dart';
import 'domain/usecases/get_my_ot_requests_usecase.dart';
import 'domain/usecases/decide_ot_usecase.dart';
import 'domain/usecases/get_ot_approvals_usecase.dart';
import 'domain/usecases/get_open_ot_posts_usecase.dart';
import 'domain/usecases/get_ot_request_usecase.dart';
import 'domain/usecases/join_ot_post_usecase.dart';

/// Composition root for the overtime feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the data source.
final otRemoteDataSourceProvider = Provider<OtRemoteDataSource>(
  (ref) => OtRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final otRepositoryProvider = Provider<OtRepository>(
  (ref) => OtRepositoryImpl(remote: ref.watch(otRemoteDataSourceProvider)),
);

final askOtUseCaseProvider = Provider<AskOtUseCase>(
  (ref) => AskOtUseCase(ref.watch(otRepositoryProvider)),
);

final getMyOtRequestsUseCaseProvider = Provider<GetMyOtRequestsUseCase>(
  (ref) => GetMyOtRequestsUseCase(ref.watch(otRepositoryProvider)),
);

final decideOtUseCaseProvider = Provider<DecideOtUseCase>(
  (ref) => DecideOtUseCase(ref.watch(otRepositoryProvider)),
);

final getOtApprovalsUseCaseProvider = Provider<GetOtApprovalsUseCase>(
  (ref) => GetOtApprovalsUseCase(ref.watch(otRepositoryProvider)),
);

final getOtRequestUseCaseProvider = Provider<GetOtRequestUseCase>(
  (ref) => GetOtRequestUseCase(ref.watch(otRepositoryProvider)),
);

final editOtUseCaseProvider = Provider<EditOtUseCase>(
  (ref) => EditOtUseCase(ref.watch(otRepositoryProvider)),
);

final cancelOtUseCaseProvider = Provider<CancelOtUseCase>(
  (ref) => CancelOtUseCase(ref.watch(otRepositoryProvider)),
);

final getOpenOtPostsUseCaseProvider = Provider<GetOpenOtPostsUseCase>(
  (ref) => GetOpenOtPostsUseCase(ref.watch(otRepositoryProvider)),
);

final joinOtPostUseCaseProvider = Provider<JoinOtPostUseCase>(
  (ref) => JoinOtPostUseCase(ref.watch(otRepositoryProvider)),
);

/// The signed-in user's own employee id, or null when it is not known (no
/// session yet, or a login with no staff record). The OT request page shows
/// Edit and Cancel only on the user's own request.
final otOwnEmployeeIdProvider = Provider<String?>(
  (ref) => ref.watch(
    authSessionProvider.select(
      (session) => session.valueOrNull?.user?.employeeId,
    ),
  ),
);
