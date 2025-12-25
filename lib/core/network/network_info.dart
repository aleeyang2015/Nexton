import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/failure.dart';

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

/// Network interceptor for handling errors and adding headers
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
    final failure = _handleDioError(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: failure,
    ));
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Successful response handling
    super.onResponse(response, handler);
  }

  /// Convert Dio exceptions to Failure objects
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Failure.network(
          message: 'Request timeout. Please try again.',
          errorCode: 'TIMEOUT',
        );
      case DioExceptionType.badResponse:
        return Failure.network(
          message: _getErrorMessage(error.response?.statusCode),
          statusCode: error.response?.statusCode,
          errorCode: error.response?.statusMessage,
        );
      case DioExceptionType.cancel:
        return Failure.network(
          message: 'Request was cancelled',
          errorCode: 'CANCELLED',
        );
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return Failure.network(
            message: 'No internet connection',
            errorCode: 'NO_INTERNET',
          );
        }
        return Failure.unknown(
          message: error.message ?? 'Unknown network error',
          error: error.error,
        );
      default:
        return Failure.unknown(
          message: error.message ?? 'Unknown network error',
          error: error.error,
        );
    }
  }

  /// Get user-friendly error message based on status code
  String _getErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }
}