import '../../../core/errors/failure.dart';

/// auth.md's `isAuthFailure`: HTTP **400 / 401 / 403 / 422** mean "the
/// credentials were wrong", everything else means "the request didn't get
/// through". [ApiErrorMapper] already routes those status codes to
/// [AuthFailure] / [ValidationFailure], so the check is a type test here.
///
/// The login throttle (**429**) is deliberately *not* a credential failure —
/// the typed password survives a throttle so the user can just wait and retry.
extension AuthFailureX on Failure {
  bool get isCredentialFailure =>
      this is AuthFailure || this is ValidationFailure;

  /// True when the session itself is gone and only a fresh login can fix it.
  bool get isSessionFailure => this is AuthFailure;
}
