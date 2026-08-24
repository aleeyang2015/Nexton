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

  /// Attendance pre-flight checks. The clock-in/out spec asks the client to
  /// refuse these punches itself rather than spend a round trip earning a
  /// guaranteed rejection (§7 rules 1 and 2).
  static const String locationUnavailable = 'locationUnavailable';
  static const String locationServiceDisabled = 'locationServiceDisabled';
  static const String locationPermissionDenied = 'locationPermissionDenied';
  static const String locationPermissionDeniedForever =
      'locationPermissionDeniedForever';
  static const String locationTimeout = 'locationTimeout';
  static const String wifiUnavailable = 'wifiUnavailable';
  static const String fieldReasonRequired = 'fieldReasonRequired';
  static const String mockLocationDetected = 'mockLocationDetected';
}
