import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'network_info.dart';

/// Single Dio instance shared by the whole app
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.interceptors.add(NetworkInterceptor());
  return dio;
});

/// REST client every remote data source depends on
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider));
});

/// Connectivity check
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.watch(dioProvider));
});
