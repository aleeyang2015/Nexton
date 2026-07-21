import '../errors/failure.dart';
import '../errors/exceptions.dart';
import 'result.dart';

/// Base repository that all repositories should extend.
/// Turns thrown exceptions from the data layer into a [Result].
abstract class BaseRepository {
  /// Runs [operation] and wraps the outcome in a [Result]
  FutureResult<T> guard<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return Result.success(await operation());
    } catch (e) {
      return Result.failure(_toFailure(e));
    }
  }

  /// Convert exceptions to Failure objects
  Failure _toFailure(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is AppException) {
      return exception.toFailure();
    }

    // Handle specific exception types
    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('TimeoutException') ||
        exception.toString().contains('ConnectionException')) {
      return Failure.network(
        message: 'Network connection error',
      );
    }

    if (exception.toString().contains('FormatException')) {
      return Failure.validation(
        message: 'Invalid data format',
      );
    }

    return Failure.unknown(
      message: exception.toString(),
      error: exception,
    );
  }
}
