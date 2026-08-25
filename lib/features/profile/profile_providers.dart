import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/profile_remote_data_source.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/get_my_profile_usecase.dart';

/// Composition root for the profile feature: the one place the data layer is
/// constructed and bound to the domain contracts. Presentation consumes only
/// the use case provider, never the datasource.
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(remote: ref.watch(profileRemoteDataSourceProvider));
});

final getMyProfileUseCaseProvider = Provider<GetMyProfileUseCase>((ref) {
  return GetMyProfileUseCase(ref.watch(profileRepositoryProvider));
});
