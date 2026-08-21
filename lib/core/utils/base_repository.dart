import 'package:dio/dio.dart';

import '../errors/failure.dart';
import '../errors/exceptions.dart';
import '../network/api_error_mapper.dart';
import 'result.dart';

/// Base repository that all repositories should extend.
/// Turns thrown exceptions from the data layer into a [Result].
abstract class BaseRepository {
  /// Runs [operation] and wraps the outcome in a [Result]
  FutureResult<T> guard<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } catch (e) {
      return Result.failure(toFailure(e));
    }
  }

  /// Convert exceptions to Failure objects. Subclasses call this when they
  /// need to branch on the failure kind inside a [guard] block.
  Failure toFailure(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is AppException) {
      return exception.toFailure();
    }

    // NetworkInterceptor already mapped the transport error and parked it on
    // `error`; anything that bypassed it still maps cleanly here.
    if (exception is DioException) {
      final mapped = exception.error;
      return mapped is Failure
          ? mapped
          : ApiErrorMapper.fromDioException(exception);
    }

    if (exception is FormatException) {
      return Failure.validation(message: exception.message);
    }

    // Handle specific exception types
    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('TimeoutException') ||
        exception.toString().contains('ConnectionException')) {
      return Failure.network(message: 'Network connection error');
    }

    if (exception.toString().contains('FormatException')) {
      return Failure.validation(message: 'Invalid data format');
    }

    return Failure.unknown(message: exception.toString(), error: exception);
  }
}
