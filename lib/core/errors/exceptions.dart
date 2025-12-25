import 'failure.dart';

/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final dynamic error;

  const AppException(this.message, {this.error});

  @override
  String toString() => 'AppException: $message';

  /// Convert exception to Failure
  Failure toFailure();
}

/// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;
  final String? errorCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    this.errorCode,
    super.error,
  });

  /// Convert NetworkException to Failure
  @override
  Failure toFailure() {
    return Failure.network(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }
}

/// Server-side exceptions
class ServerException extends AppException {
  final int? statusCode;
  final String? errorCode;

  const ServerException(
    super.message, {
    this.statusCode,
    this.errorCode,
    super.error,
  });

  /// Convert ServerException to Failure
  @override
  Failure toFailure() {
    return Failure.server(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }
}

/// Validation exceptions
class ValidationException extends AppException {
  final String? field;

  const ValidationException(
    super.message, {
    this.field,
    super.error,
  });

  /// Convert ValidationException to Failure
  @override
  Failure toFailure() {
    return Failure.validation(
      message: message,
      field: field,
    );
  }
}

/// Cache-related exceptions
class CacheException extends AppException {
  final String? operation;

  const CacheException(
    super.message, {
    this.operation,
    super.error,
  });

  /// Convert CacheException to Failure
  @override
  Failure toFailure() {
    return Failure.cache(
      message: message,
      operation: operation,
    );
  }
}

/// Authentication/Authorization exceptions
class AuthException extends AppException {
  final String? code;

  const AuthException(
    super.message, {
    this.code,
    super.error,
  });

  /// Convert AuthException to Failure
  @override
  Failure toFailure() {
    return Failure.auth(
      message: message,
      code: code,
    );
  }
}