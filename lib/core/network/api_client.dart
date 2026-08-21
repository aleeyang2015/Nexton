import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// REST API client using Dio
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  /// Base options every client in the app shares — the authed [ApiClient] and
  /// the bare Dio the token refresh runs on.
  static BaseOptions buildBaseOptions() => BaseOptions(
    baseUrl: '${AppConstants.baseUrl}/${AppConstants.apiVersion}',
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {
      AppConstants.acceptHeader: AppConstants.jsonContentType,
      AppConstants.contentTypeHeader: AppConstants.jsonContentType,
      AppConstants.userAgentHeader: 'NextOn App ${AppConstants.appVersion}',
      // Dev-only override on the backend; harmless in production.
      AppConstants.tenantSlugHeader: AppConstants.tenantSlug,
    },
  );

  /// Setup Dio interceptors
  void _setupInterceptors() {
    _dio.options = buildBaseOptions();

    // Request/response bodies carry tokens and profile data — never log them
    // outside a debug build.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload file
  Future<Response<T>> upload<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: options,
    );
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
    );
  }
}
