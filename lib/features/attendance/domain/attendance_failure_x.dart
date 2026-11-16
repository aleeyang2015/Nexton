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

  /// The punch was refused and retrying as it stands cannot help: a signal
  /// the client would not send it without — GPS off, no permission, a mock
  /// position — or a refusal from the server with its code, such as
  /// `MODULE_NOT_ACTIVE`. Both are shown in a dialog the user acknowledges.
  bool get isMissingEvidence => this is ValidationFailure;

  /// Worth offering a retry button for: the request never reached a verdict —
  /// the server broke (5xx), or there was no answer at all (a timeout, no
  /// connection: a network failure with no status). A 4xx is a verdict. The
  /// same punch would get the same refusal, and for some refusals each try
  /// alerts the employee's head and HR.
  bool get isRetryable =>
      this is ServerFailure || (this is NetworkFailure && _statusCode == null);

  /// The login has no employee record (`400 EMPLOYEE_NOT_FOUND`), so there is
  /// no attendance to load, now or on a retry: only HR can link the account.
  /// It decides one thing, that no Retry is offered; the text comes from
  /// `failure.localize`.
  bool get isEmployeeNotLinked => switch (this) {
    ValidationFailure(:final code) => code == _employeeNotFoundCode,
    _ => false,
  };

  static const String _employeeNotFoundCode = 'EMPLOYEE_NOT_FOUND';

  int? get _statusCode => switch (this) {
    NetworkFailure(:final statusCode) => statusCode,
    ServerFailure(:final statusCode) => statusCode,
    _ => null,
  };
}
