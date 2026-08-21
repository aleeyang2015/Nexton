import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_interceptor.dart';
import '../../core/network/network_providers.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/change_password_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/restore_session_usecase.dart';

/// Composition root for the auth feature: the single place where the data
/// layer is constructed and bound to the domain contracts. Presentation
/// consumes only the use case providers below, never the datasources.

/// Talks to `/auth/login`, `/auth/me` and `/auth/change-password` through the
/// shared API client. `/auth/refresh` is not here — it belongs to
/// [AuthInterceptor], which drives it off a 401.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    store: ref.watch(secureStoreProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Exposed as the abstract type so consumers never see the impl
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    sessionExpired: ref.watch(authInterceptorProvider).onSessionExpired,
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});
