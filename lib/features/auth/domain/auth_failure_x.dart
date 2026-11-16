import '../../../core/errors/failure.dart';

/// auth.md's `isAuthFailure`: on the login and change-password calls, HTTP
/// **400 / 401 / 403 / 422** mean "the server refused these credentials",
/// everything else means "the request didn't get through". [ApiErrorMapper]
/// routes those status codes to [AuthFailure] / [ValidationFailure], so the
/// check is a type test here.
///
/// A 403 is no longer always an [AuthFailure]: only `USER_INACTIVE` and
/// `TENANT_INACTIVE` are. Every other 403 is a [ValidationFailure] that keeps
/// its code, a refusal of one request that leaves the session alone.
///
/// The login throttle (**429**) is deliberately *not* a credential failure —
/// the typed password survives a throttle so the user can just wait and retry.
extension AuthFailureX on Failure {
  bool get isCredentialFailure =>
      this is AuthFailure || this is ValidationFailure;

  /// True when the session itself is gone and only a fresh login can fix it:
  /// a 401, or a switched-off user or company.
  bool get isSessionFailure => this is AuthFailure;
}
