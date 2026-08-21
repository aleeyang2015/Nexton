import 'package:dio/dio.dart';

import '../errors/failure.dart';
import 'api_response.dart';

/// Error codes the backend returns on the auth routes (auth.md).
class ApiErrorCodes {
  ApiErrorCodes._();

  static const String invalidRequest = 'INVALID_REQUEST';
  static const String validationError = 'VALIDATION_ERROR';
  static const String subdomainRequired = 'SUBDOMAIN_REQUIRED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String userInactive = 'USER_INACTIVE';
  static const String tooManyLoginAttempts = 'TOO_MANY_LOGIN_ATTEMPTS';
  static const String passwordMismatch = 'PASSWORD_MISMATCH';
  static const String notFound = 'NOT_FOUND';
  static const String internalError = 'INTERNAL_ERROR';
  static const String sessionExpired = 'SESSION_EXPIRED';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String timeout = 'TIMEOUT';
  static const String noInternet = 'NO_INTERNET';
  static const String cancelled = 'CANCELLED';
}

/// Turns a [DioException] into a [Failure], preferring the server's own
/// `error.code` / `error.message` over a generic status-code message.
///
/// Status → variant follows the backend contract in auth.md:
/// 401/403 (and the credential-ish 400s) are auth failures, 400/422 are
/// validation failures, 5xx are server failures, and everything else —
/// **including the 429 login throttle** — is a network failure. The login
/// screen relies on that split to decide whether to clear the password field.
class ApiErrorMapper {
  ApiErrorMapper._();

  static Failure fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.network(
          message: 'Request timeout. Please try again.',
          errorCode: ApiErrorCodes.timeout,
        );

      case DioExceptionType.cancel:
        return const Failure.network(
          message: 'Request was cancelled',
          errorCode: ApiErrorCodes.cancelled,
        );

      case DioExceptionType.connectionError:
        return const Failure.network(
          message: 'No internet connection',
          errorCode: ApiErrorCodes.noInternet,
        );

      case DioExceptionType.badResponse:
        return _fromResponse(error.response);

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return const Failure.network(
            message: 'No internet connection',
            errorCode: ApiErrorCodes.noInternet,
          );
        }
        return Failure.unknown(
          message: error.message ?? 'Unknown network error',
          error: error.error,
        );
    }
  }

  static Failure _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final apiError = ApiError.tryParse(response?.data);
    final code = apiError?.code;
    final message = apiError?.bestMessage ?? defaultMessageFor(status);

    if (status == null) {
      return Failure.unknown(message: message);
    }

    if (status == 401 || status == 403 || _isCredentialCode(code)) {
      return Failure.auth(message: message, code: code);
    }

    if (status == 422 || status == 400) {
      return Failure.validation(message: message, field: apiError?.firstField);
    }

    if (status >= 500) {
      return Failure.server(
        message: message,
        statusCode: status,
        errorCode: code,
      );
    }

    // 404, 429 (login throttle) and any other 4xx.
    return Failure.network(
      message: message,
      statusCode: status,
      errorCode: code,
    );
  }

  /// 400s that mean "your credentials are wrong", not "your JSON is wrong".
  static bool _isCredentialCode(String? code) =>
      code == ApiErrorCodes.passwordMismatch ||
      code == ApiErrorCodes.subdomainRequired;

  /// Fallback copy when the server sent no message.
  static String defaultMessageFor(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Some of the information you entered is invalid.';
      case 429:
        return 'Too many attempts. Please try again later.';
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
