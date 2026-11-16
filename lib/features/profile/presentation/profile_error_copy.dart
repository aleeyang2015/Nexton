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
/// Retry is withheld for one thing only: a **refusal the server put its own
/// code on** — `EMPLOYEE_NOT_FOUND`, `MODULE_NOT_ACTIVE`, `FORBIDDEN`, … The
/// same request gets the same answer, and only HR or the company can change
/// it. The text is the one for that code in the shared table
/// (`failure.localize`).
///
/// Everything else can be retried, because nothing else on these screens
/// reloads the profile and a user left without Retry is stuck until the app
/// restarts:
///
/// * the company's system not being ready (`503 TENANT_UNAVAILABLE` /
///   `TENANT_LOOKUP_FAILED`) and a rate limit (429) keep their own text from
///   the shared table;
/// * a 5xx, no connection, a timeout, a 408, and an answer that is not the
///   API's at all — a 4xx with no code from a proxy, a Wi-Fi sign-in page
///   where JSON was expected — say "could not load your profile". A refusal
///   with no code has no text of its own, only the server's English or a
///   parser's message, and neither belongs in front of the user.
///
/// The app does not re-check the backend's rules here: it only reads the
/// kind of failure and its code.
({String text, bool canRetry}) profileErrorCopy(
  AppLocalizations l10n,
  Object error,
) {
  final retry = (text: l10n.profileLoadFailed, canRetry: true);
  if (error is! Failure) return retry;

  ({String text, bool canRetry}) refusal() =>
      (text: error.localize(l10n), canRetry: false);

  return switch (error) {
    ValidationFailure(:final code) => code == null ? retry : refusal(),
    AuthFailure(:final code) => code == null ? retry : refusal(),
    ServerFailure(:final errorCode) =>
      _companyNotReady.contains(errorCode)
          ? (text: error.localize(l10n), canRetry: true)
          : retry,
    NetworkFailure(:final statusCode, :final errorCode) => switch (statusCode) {
      // The request never got an answer: no connection, a timeout.
      null => retry,
      // The server's own "try again later"; the shared table has its text.
      429 => (text: error.localize(l10n), canRetry: true),
      // The server gave up waiting for the request.
      408 => retry,
      // Any other 4xx the mapper had no narrower kind for (a 404, say).
      _ => errorCode == null ? retry : refusal(),
    },
    _ => retry,
  };
}

/// The 5xx codes that say the company's own system is not ready, which the
/// shared table words better than "could not load".
const Set<String?> _companyNotReady = {
  ApiErrorCodes.tenantUnavailable,
  ApiErrorCodes.tenantLookupFailed,
};
