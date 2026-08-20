import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';

/// Composition root for the auth feature: the single place where the data
/// layer is constructed and bound to the domain contracts. Presentation
/// consumes only the use case providers below, never the datasources.

/// Remote source for auth.
/// Currently the fake — swap to `AuthRemoteDataSourceImpl(ref.watch(apiClientProvider))`
/// once the backend exists. That one line is the whole migration.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FakeAuthRemoteDataSource();
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return InMemoryAuthLocalDataSource();
});

/// Exposed as the abstract type so consumers never see the impl
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});
