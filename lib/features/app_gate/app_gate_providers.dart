import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'data/datasources/app_info_remote_data_source.dart';
import 'data/repositories/app_info_repository_impl.dart';
import 'domain/repositories/app_info_repository.dart';
import 'domain/usecases/get_app_info_usecase.dart';

/// `android` or `ios`: the record the gate asks for (#57).
final appPlatformProvider = Provider<String>(
  (ref) => Platform.isIOS ? 'ios' : 'android',
);

/// A Dio of its own, with the App's base options and no auth interceptor,
/// like the refresh client: the check is public. It connects within the
/// check's own limit, so a check never takes much longer than that.
final appInfoClientProvider = Provider<Dio>(
  (ref) => Dio(
    ApiClient.buildBaseOptions().copyWith(
      connectTimeout: AppInfoRemoteDataSource.timeout,
    ),
  ),
);

final appInfoRemoteDataSourceProvider = Provider<AppInfoRemoteDataSource>(
  (ref) => AppInfoRemoteDataSourceImpl(ref.watch(appInfoClientProvider)),
);

final appInfoRepositoryProvider = Provider<AppInfoRepository>(
  (ref) => AppInfoRepositoryImpl(ref.watch(appInfoRemoteDataSourceProvider)),
);

final getAppInfoUseCaseProvider = Provider<GetAppInfoUseCase>(
  (ref) => GetAppInfoUseCase(ref.watch(appInfoRepositoryProvider)),
);
