import '../errors/failure.dart';
import '../errors/exceptions.dart';
import 'either.dart';

/// Base repository interface that all repositories should extend
/// Provides common functionality for data operations
abstract class BaseRepository {
  /// Handle exceptions and convert to Either&lt;Failure, T&gt;
  FutureEither<T> handleException<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Either.right(result);
    } catch (e) {
      return Either.left(_handleException(e));
    }
  }

  /// Convert exceptions to Failure objects
  Failure _handleException(dynamic exception) {
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