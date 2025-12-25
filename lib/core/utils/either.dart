import 'package:freezed_annotation/freezed_annotation.dart';
import '../errors/failure.dart';

part 'either.freezed.dart';

/// Either type for handling success or failure
/// Used to represent operations that can fail
@freezed
class Either<L, R> with _$Either<L, R> {
  /// Left represents a failure
  const factory Either.left(L value) = Left<L, R>;

  /// Right represents a success
  const factory Either.right(R value) = Right<L, R>;
}

/// Type alias for Either with Failure as left type
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Extension methods for Either
extension EitherExtension<L, R> on Either<L, R> {
  /// Maps the success value if Right, otherwise returns Left unchanged
  Either<L, R2> map<R2>(R2 Function(R value) f) {
    return when(
      left: (value) => Either.left(value),
      right: (value) => Either.right(f(value)),
    );
  }

  /// Maps the failure value if Left, otherwise returns Right unchanged
  Either<L2, R> mapLeft<L2>(L2 Function(L value) f) {
    return when(
      left: (value) => Either.left(f(value)),
      right: (value) => Either.right(value),
    );
  }

  /// Returns the success value or null if Left
  R? get rightOrNull {
    return when(
      left: (value) => null,
      right: (value) => value,
    );
  }

  /// Returns the failure value or null if Right
  L? get leftOrNull {
    return when(
      left: (value) => value,
      right: (value) => null,
    );
  }

  /// Returns true if Right
  bool get isRight => when(left: (value) => false, right: (value) => true);

  /// Returns true if Left
  bool get isLeft => when(left: (value) => true, right: (value) => false);

  /// Executes a function based on the Either value
  void fold(
    void Function(L value) onLeft,
    void Function(R value) onRight,
  ) {
    when(
      left: (value) => onLeft(value),
      right: (value) => onRight(value),
    );
  }

  /// Returns the success value or throws if Left
  R get rightOrThrow {
    return when(
      left: (value) => throw Exception('Left value: $value'),
      right: (value) => value,
    );
  }

  /// Returns the success value or a default value if Left
  R rightOrDefault(R defaultValue) {
    return when(
      left: (value) => defaultValue,
      right: (value) => value,
    );
  }
}