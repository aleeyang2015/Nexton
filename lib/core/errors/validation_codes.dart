/// Semantic codes a client-side [ValidationFailure] message can carry.
///
/// The domain layer (login/change-password use cases) stays free of UI text
/// by returning one of these instead of a human-readable string; the
/// presentation layer maps a code to a localized message via
/// `FailureLocalization` in `core/l10n/failure_localizer.dart`.
class ValidationCode {
  ValidationCode._();

  static const String emailRequired = 'emailRequired';
  static const String emailInvalid = 'emailInvalid';
  static const String passwordRequired = 'passwordRequired';
  static const String passwordTooShort = 'passwordTooShort';
  static const String currentPasswordRequired = 'currentPasswordRequired';
  static const String newPasswordSameAsCurrent = 'newPasswordSameAsCurrent';
  static const String confirmPasswordMismatch = 'confirmPasswordMismatch';
}
