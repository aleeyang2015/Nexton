import '../../../core/errors/failure.dart';
import '../../../core/l10n/failure_localizer.dart';
import '../../../core/network/api_error_mapper.dart';
import '../../../l10n/generated/app_localizations.dart';

/// What to say when `GET /core_hr/employees/me` fails, and whether trying
/// again can help.
///
/// The profile page and the home header both call this, so they can never
/// disagree about the wording or about offering Retry.
///
/// * A refusal — the server understood and said no (`EMPLOYEE_NOT_FOUND`,
///   `MODULE_NOT_ACTIVE`, any other 4xx) — shows the text for its code from
///   the shared table (`failure.localize`). No Retry: the same request gets
///   the same answer, and only HR or the company can change it.
/// * The company's system not being ready (`503 TENANT_UNAVAILABLE` /
///   `TENANT_LOOKUP_FAILED`) has its own text in that table too, and is worth
///   retrying.
/// * Anything else — a 5xx, no connection, a timeout, an unreadable answer —
///   is "could not load your profile", with Retry.
///
/// The app does not re-check the backend's rules here: it only reads the
/// kind of failure and its code.
({String text, bool canRetry}) profileErrorCopy(
  AppLocalizations l10n,
  Object error,
) {
  if (error is! Failure) {
    return (text: l10n.profileLoadFailed, canRetry: true);
  }

  return switch (error) {
    ValidationFailure() ||
    AuthFailure() => (text: error.localize(l10n), canRetry: false),
    ServerFailure(:final errorCode) => (
      text: _companyNotReady.contains(errorCode)
          ? error.localize(l10n)
          : l10n.profileLoadFailed,
      canRetry: true,
    ),
    // No status: the request never got an answer (no connection, a timeout).
    // With one, it is a 4xx the mapper had no narrower kind for, a verdict
    // like any other refusal.
    NetworkFailure(:final statusCode) =>
      statusCode == null
          ? (text: l10n.profileLoadFailed, canRetry: true)
          : (text: error.localize(l10n), canRetry: false),
    _ => (text: l10n.profileLoadFailed, canRetry: true),
  };
}

/// The 5xx codes that say the company's own system is not ready, which the
/// shared table words better than "could not load".
const Set<String?> _companyNotReady = {
  ApiErrorCodes.tenantUnavailable,
  ApiErrorCodes.tenantLookupFailed,
};
