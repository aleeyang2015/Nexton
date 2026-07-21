import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Base failure class for handling errors in the application
@freezed
class Failure with _$Failure {
  /// Network-related failures (API calls, connectivity, etc.)
  const factory Failure.network({
    required String message,
    int? statusCode,
    String? errorCode,
  }) = NetworkFailure;

  /// Server-side failures (5xx errors, maintenance, etc.)
  const factory Failure.server({
    required String message,
    int? statusCode,
    String? errorCode,
  }) = ServerFailure;

  /// Validation failures (form validation, data validation, etc.)
  const factory Failure.validation({
    required String message,
    String? field,
  }) = ValidationFailure;

  /// Cache-related failures (storage, retrieval, etc.)
  const factory Failure.cache({
    required String message,
    String? operation,
  }) = CacheFailure;

  /// Authentication/Authorization failures
  const factory Failure.auth({
    required String message,
    String? code,
  }) = AuthFailure;

  /// Unknown/unexpected failures
  const factory Failure.unknown({
    required String message,
    dynamic error,
  }) = UnknownFailure;
}

extension FailureX on Failure {
  /// The human-readable message, whichever variant this is
  String get message => when(
        network: (message, _, __) => message,
        server: (message, _, __) => message,
        validation: (message, _) => message,
        cache: (message, _) => message,
        auth: (message, _) => message,
        unknown: (message, _) => message,
      );
}