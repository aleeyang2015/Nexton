import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/failure.dart';
import 'api_response.dart';

/// Error codes the backend returns on the auth routes (auth.md), and the ones
/// every route can answer with: company, session, permission and module.
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
  static const String missingToken = 'MISSING_TOKEN';
  static const String invalidTokenFormat = 'INVALID_TOKEN_FORMAT';
  static const String invalidTokenType = 'INVALID_TOKEN_TYPE';
  static const String missingTenant = 'MISSING_TENANT';
  static const String tenantNotFound = 'TENANT_NOT_FOUND';
  static const String tenantInactive = 'TENANT_INACTIVE';
  static const String tenantLookupFailed = 'TENANT_LOOKUP_FAILED';
  static const String tenantUnavailable = 'TENANT_UNAVAILABLE';
  static const String tenantMismatch = 'TENANT_MISMATCH';
  static const String forbidden = 'FORBIDDEN';
  static const String moduleNotActive = 'MODULE_NOT_ACTIVE';
  static const String rateLimited = 'RATE_LIMITED';
  static const String employeeNotFound = 'EMPLOYEE_NOT_FOUND';
  static const String timeout = 'TIMEOUT';
  static const String noInternet = 'NO_INTERNET';
  static const String cancelled = 'CANCELLED';
}

/// Turns a [DioException] into a [Failure], preferring the server's own
/// `error.code` / `error.message` over a generic status-code message.
///
/// Status → variant:
///
/// * **auth** — the credentials or the session: every 401, the credential-ish
///   400s (`PASSWORD_MISMATCH`, `SUBDOMAIN_REQUIRED`), and the two 403s that
///   end a session, `USER_INACTIVE` and `TENANT_INACTIVE`. The App reads an
///   auth failure as "only a fresh login fixes this".
/// * **validation** — the server refused the request and there is nothing to
///   retry: every other 403 (`FORBIDDEN`, `MODULE_NOT_ACTIVE`, `NOT_APPROVER`,
///   …) and every 400/422. The failure keeps the server's `code`, so a 403 is
///   shown as a refusal and never mistaken for a lost session.
/// * **server** — 5xx.
/// * **network** — everything else, **including the 429 throttles**.
///
/// The login screen relies on that split to decide whether to clear the
/// password field.
///
/// A throttled response's `Retry-After` is carried through on the failure
/// (auth-login.md §2). It has to be read *here*: this is the last point that
/// still holds the raw [Response], and [NetworkInterceptor] rejects the chain
/// with nothing but the mapped [Failure].
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

    if (status == 401 ||
        _isCredentialCode(code) ||
        (status == 403 && _endsSession(code))) {
      return Failure.auth(message: message, code: code);
    }

    if (status == 403 || status == 422 || status == 400) {
      return Failure.validation(
        message: message,
        field: apiError?.firstField,
        code: code,
      );
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
      retryAfter: _retryAfterOf(response),
    );
  }

  /// The `Retry-After` delay a response asked for, or null when it asked for
  /// none.
  ///
  /// Only the delta-seconds form is read — the one the backend's throttle
  /// sends. RFC 9110 also allows an HTTP-date, which we treat as "unknown"
  /// rather than guess at clock skew between device and server. A negative or
  /// unparseable value is unknown too; it must never become a zero-length
  /// wait that looks deliberate.
  static Duration? _retryAfterOf(Response<dynamic>? response) {
    final raw = response?.headers.value(AppConstants.retryAfterHeader)?.trim();
    if (raw == null || raw.isEmpty) return null;

    final seconds = int.tryParse(raw);
    if (seconds == null || seconds <= 0) return null;

    return Duration(seconds: seconds);
  }

  /// 400s that mean "your credentials are wrong", not "your JSON is wrong".
  static bool _isCredentialCode(String? code) =>
      code == ApiErrorCodes.passwordMismatch ||
      code == ApiErrorCodes.subdomainRequired;

  /// 403s after which the account cannot go on: the user, or the whole
  /// company, was switched off. Every other 403 is a refusal of one request.
  static bool _endsSession(String? code) =>
      code == ApiErrorCodes.userInactive ||
      code == ApiErrorCodes.tenantInactive;

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
