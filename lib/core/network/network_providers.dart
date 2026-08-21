import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';
import 'secure_store.dart';
import 'token_storage.dart';

/// Overridden in `main()` once SharedPreferences has been opened, so every
/// consumer below can stay synchronous.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Keychain-backed store. Overridden in `main()` with the instance the
/// startup migration already ran against, and swapped for an in-memory double
/// in tests.
final secureStoreProvider = Provider<SecureStore>((ref) {
  throw UnimplementedError(
    'secureStoreProvider must be overridden in ProviderScope',
  );
});

/// Access/refresh token persistence used by [AuthInterceptor] and the auth
/// feature's local data source.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(ref.watch(secureStoreProvider));
});

/// Bare client for `POST /auth/refresh`. Deliberately free of interceptors so
/// a refresh can never re-enter the 401 handling that triggered it.
final refreshClientProvider = Provider<Dio>((ref) {
  return Dio(ApiClient.buildBaseOptions());
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final interceptor = AuthInterceptor(
    tokenStorage: ref.watch(tokenStorageProvider),
    refreshClient: ref.watch(refreshClientProvider),
  );
  ref.onDispose(interceptor.dispose);
  return interceptor;
});

/// Single Dio instance shared by the whole app.
///
/// Interceptor order matters: [AuthInterceptor] must see a 401 before
/// [NetworkInterceptor] converts it into a [Failure] and rejects the chain.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  ref.watch(authInterceptorProvider).attachTo(dio);
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
