import 'result.dart';

/// Base use case interface
/// All use cases should extend this interface
abstract class BaseUseCase<T, P> {
  /// Execute the use case with given parameters
  FutureResult<T> call(P params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<T> {
  /// Execute the use case without parameters
  FutureResult<T> call();
}

/// Stream-based use case interface
abstract class StreamUseCase<T, P> {
  /// Execute the use case and return a stream
  Stream<Result<T>> call(P params);
}

/// Void parameter type for use cases that don't require parameters
class NoParams {
  const NoParams();
}

/// Base parameters class that all parameter classes should extend
abstract class BaseParams {
  /// Validate the parameters before the use case runs
  Result<Unit> validate();
}