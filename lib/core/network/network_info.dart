import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_error_mapper.dart';

/// Interface for checking network connectivity
abstract class NetworkInfo {
  /// Check if device is connected to internet
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo using Dio
class NetworkInfoImpl implements NetworkInfo {
  final Dio dio;

  NetworkInfoImpl(this.dio);

  @override
  Future<bool> get isConnected async {
    try {
      final response = await dio.get(
        'https://www.google.com',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Adds the headers every request needs and normalises transport errors into a
/// [Failure] carried on `DioException.error`, which [BaseRepository] unwraps.
///
/// Register this **after** any interceptor that needs to inspect the raw
/// response (e.g. AuthInterceptor's 401 refresh) — it rejects the error chain.
class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add common headers
    options.headers.addAll({
      AppConstants.acceptHeader: AppConstants.jsonContentType,
      AppConstants.userAgentHeader: 'NextOn App ${AppConstants.appVersion}',
    });

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert Dio exceptions to Failure
    final failure = ApiErrorMapper.fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
      ),
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Successful response handling
    super.onResponse(response, handler);
  }
}
