import 'package:freezed_annotation/freezed_annotation.dart';
import '../errors/failure.dart';

part 'result.freezed.dart';

/// Result type for operations that can fail.
/// Every repository method returns this instead of throwing.
@freezed
class Result<T> with _$Result<T> {
  const Result._();

  /// Operation completed and produced [data]
  const factory Result.success(T data) = Success<T>;

  /// Operation failed with [failure]
  const factory Result.failure(Failure failure) = Failed<T>;

  /// True when this holds a value
  bool get isSuccess => this is Success<T>;

  /// True when this holds a failure
  bool get isFailure => this is Failed<T>;

  /// The value, or null when this is a failure
  T? get dataOrNull => when(
        success: (data) => data,
        failure: (_) => null,
      );

  /// The failure, or null when this is a success
  Failure? get failureOrNull => when(
        success: (_) => null,
        failure: (failure) => failure,
      );

  /// The value, or [fallback] when this is a failure
  T getOrElse(T fallback) => dataOrNull ?? fallback;

  /// Transforms the value, leaving a failure untouched
  Result<R> mapData<R>(R Function(T data) transform) => when(
        success: (data) => Result<R>.success(transform(data)),
        failure: (failure) => Result<R>.failure(failure),
      );

  /// Collapses both branches into a single value
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) =>
      when(
        success: onSuccess,
        failure: onFailure,
      );
}

/// Shorthand for an async operation returning a [Result]
typedef FutureResult<T> = Future<Result<T>>;

/// Stand-in for operations that succeed without producing a value
class Unit {
  const Unit();
  static const instance = Unit();
}