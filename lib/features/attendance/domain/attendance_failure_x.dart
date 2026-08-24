import '../../../core/errors/failure.dart';

/// Classifies the failures a punch can come back with, so the notifier and
/// the card never inspect status codes themselves.
extension AttendanceFailureX on Failure {
  /// The mobile clock-in rate limiter fired (§5.3). The punch did *not*
  /// happen, and retrying immediately will only earn another 429.
  bool get isThrottled => this is NetworkFailure && _statusCode == 429;

  /// The session is gone; only a fresh login fixes it. The 401 interceptor
  /// has already torn the session down by the time this is true.
  bool get isSessionFailure => this is AuthFailure;

  /// A signal the client itself refused to send a punch without — GPS off,
  /// no BSSID, no field-work reason (§7 rules 1–2).
  bool get isMissingEvidence => this is ValidationFailure;

  /// Worth offering a retry button for: the request never reached a verdict.
  bool get isRetryable =>
      this is ServerFailure || (this is NetworkFailure && !isThrottled);

  int? get _statusCode => switch (this) {
    NetworkFailure(:final statusCode) => statusCode,
    ServerFailure(:final statusCode) => statusCode,
    _ => null,
  };
}
