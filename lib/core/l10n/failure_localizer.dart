import '../constants/app_constants.dart';
import '../errors/failure.dart';
import '../errors/validation_codes.dart';
import '../network/api_error_mapper.dart';
import '../../l10n/generated/app_localizations.dart';

/// Turns a [Failure] into UI copy, in the active locale.
///
/// Backend/API values themselves are never localized (auth.md's error codes
/// stay exactly as the server sends them) — only how they're *displayed* to
/// the user changes here. A code this app doesn't recognize falls back to
/// the failure's own message (e.g. a field-scoped 422 the backend sent with
/// no code to look up), so nothing is ever hidden from the user.
extension FailureLocalization on Failure {
  String localize(AppLocalizations l10n) => when(
        network: (message, statusCode, errorCode) =>
            _byErrorCode(l10n, errorCode) ??
            _byStatusCode(l10n, statusCode) ??
            message,
        server: (message, statusCode, errorCode) =>
            _byErrorCode(l10n, errorCode) ??
            _byStatusCode(l10n, statusCode) ??
            message,
        validation: (message, _) => _byValidationCode(l10n, message) ?? message,
        cache: (message, _) => message,
        auth: (message, code) => _byErrorCode(l10n, code) ?? message,
        unknown: (message, _) => message,
      );
}

/// Localizes a bare field-error string held directly in a form's state
/// (`LoginState.emailError`, `ChangePasswordState.newError`, …) — either one
/// of [ValidationCode]'s semantic codes, or already-human text from a
/// field-scoped 422 the backend sent with no code to look up.
String? localizeFieldError(AppLocalizations l10n, String? code) {
  if (code == null) return null;
  return _byValidationCode(l10n, code) ?? code;
}

/// Client-side rules from [ValidationCode] — the login and change-password
/// use cases return one of these instead of text.
String? _byValidationCode(AppLocalizations l10n, String code) {
  switch (code) {
    case ValidationCode.emailRequired:
      return l10n.emailRequired;
    case ValidationCode.emailInvalid:
      return l10n.emailInvalid;
    case ValidationCode.passwordRequired:
      return l10n.passwordRequired;
    case ValidationCode.passwordTooShort:
      return l10n.passwordTooShort(AppConstants.minPasswordLength);
    case ValidationCode.currentPasswordRequired:
      return l10n.currentPasswordRequired;
    case ValidationCode.newPasswordSameAsCurrent:
      return l10n.newPasswordSameAsCurrent;
    case ValidationCode.confirmPasswordMismatch:
      return l10n.confirmPasswordMismatch;
    default:
      return null;
  }
}

/// Backend error codes from [ApiErrorCodes] (auth.md).
String? _byErrorCode(AppLocalizations l10n, String? code) {
  switch (code) {
    case ApiErrorCodes.timeout:
      return l10n.requestTimeout;
    case ApiErrorCodes.cancelled:
      return l10n.requestCancelled;
    case ApiErrorCodes.noInternet:
      return l10n.noInternetConnection;
    case ApiErrorCodes.invalidCredentials:
      return l10n.invalidCredentials;
    case ApiErrorCodes.userInactive:
      return l10n.userInactive;
    case ApiErrorCodes.tooManyLoginAttempts:
      return l10n.tooManyAttempts;
    case ApiErrorCodes.passwordMismatch:
      return l10n.currentPasswordIncorrect;
    case ApiErrorCodes.notFound:
      return l10n.resourceNotFound;
    case ApiErrorCodes.internalError:
      return l10n.serverError;
    case ApiErrorCodes.sessionExpired:
    case ApiErrorCodes.invalidToken:
      return l10n.sessionExpired;
    default:
      return null;
  }
}

/// Last-resort mapping by HTTP status, for a response that carried neither a
/// message nor a recognizable error code.
String? _byStatusCode(AppLocalizations l10n, int? statusCode) {
  switch (statusCode) {
    case 400:
      return l10n.badRequest;
    case 401:
      return l10n.unauthorized;
    case 403:
      return l10n.accessForbidden;
    case 404:
      return l10n.resourceNotFound;
    case 429:
      return l10n.tooManyAttempts;
  }
  if (statusCode != null && statusCode >= 500) return l10n.serverError;
  return null;
}
