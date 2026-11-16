/// Why the App ended a session the user did not ask to end.
///
/// Carried from the network layer to the sign-in screen, which says it once.
/// A sign-out the user chose has no reason.
enum SessionEndReason {
  /// The refresh token is dead or missing: only a fresh sign-in helps.
  expired,

  /// The account was switched off (`403 USER_INACTIVE` on refresh).
  accountDisabled,

  /// The password was changed and the App could not sign in again with the
  /// new one.
  passwordChanged,

  /// The whole company was switched off (`403 TENANT_INACTIVE`).
  companyInactive,
}
