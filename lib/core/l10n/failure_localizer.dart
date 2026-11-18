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
    // The `Retry-After` a throttled response carries is state for a caller to
    // act on, not copy — the message stays the same either way.
    network: (message, statusCode, errorCode, _) =>
        _byErrorCode(l10n, errorCode) ??
        _byStatusCode(l10n, statusCode) ??
        message,
    server: (message, statusCode, errorCode) =>
        _byErrorCode(l10n, errorCode) ??
        _byStatusCode(l10n, statusCode) ??
        message,
    validation: (message, _, code) =>
        _byCorrection(l10n, message) ??
        _byValidationCode(l10n, message) ??
        _byErrorCode(l10n, code) ??
        message,
    cache: (message, _) => message,
    auth: (message, code) => _byErrorCode(l10n, code) ?? message,
    unknown: (message, _) => message,
  );
}

/// Localizes a bare field-error string held directly in a form's state
/// (`LoginState.emailError`, `ChangePasswordState.newError`, …) — one of
/// [ValidationCode]'s semantic codes, a backend error code (a wrong current
/// password is `PASSWORD_MISMATCH`), or already-human text from a
/// field-scoped 422 the backend sent with no code to look up.
String? localizeFieldError(AppLocalizations l10n, String? code) {
  if (code == null) return null;
  return _byValidationCode(l10n, code) ?? _byErrorCode(l10n, code) ?? code;
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
    case ValidationCode.locationUnavailable:
      return l10n.locationUnavailable;
    case ValidationCode.locationServiceDisabled:
      return l10n.locationServiceDisabled;
    case ValidationCode.locationPermissionDenied:
      return l10n.locationPermissionDenied;
    case ValidationCode.locationPermissionDeniedForever:
      return l10n.locationPermissionDeniedForever;
    case ValidationCode.locationTimeout:
      return l10n.locationTimeout;
    case ValidationCode.mockLocationDetected:
      return l10n.mockLocationDetected;
    case ValidationCode.correctionDateInFuture:
      return l10n.timeCorrectionDateInFuture;
    case ValidationCode.correctionDateTooOld:
      return l10n.timeCorrectionDateTooOld(
        AppConstants.timeCorrectionMaxAgeDays,
      );
    case ValidationCode.correctionShiftRequired:
      return l10n.timeCorrectionShiftRequired;
    case ValidationCode.correctionTimeRequired:
      return l10n.timeCorrectionTimeRequired;
    case ValidationCode.correctionInvalidTimes:
      return l10n.timeCorrectionInvalidTimes;
    case ValidationCode.correctionReasonRequired:
      return l10n.timeCorrectionReasonRequired;
    case ValidationCode.correctionReasonTooLong:
      return l10n.timeCorrectionReasonTooLong(
        AppConstants.timeCorrectionReasonMaxLength,
      );
    case ValidationCode.offsiteReasonRequired:
      return l10n.offsiteReasonRequired;
    case ValidationCode.offsiteReasonTooLong:
      return l10n.offsiteReasonTooLong(AppConstants.offsiteReasonMaxLength);
    case ValidationCode.offsitePhotoRequired:
      return l10n.offsitePhotoRequired;
    // Off-site approvals — the datasource encodes the one refusal a decision
    // can hit that the correction workflow doesn't share
    // (`attendance/data/datasources/offsite_error_code.dart`).
    case 'offsiteTooEarlyCheckin':
      return l10n.offsiteTooEarlyCheckin;
    // An approver's decision on an off-site scan (#46).
    // Any attendance approval (#46, #47): `ApprovalDecisionCode`.
    case 'apprAlreadyDecided':
      return l10n.apprAlreadyDecided;
    case 'apprAnotherApprover':
      return l10n.apprAnotherApprover;
    case 'apprCannotDecideOwn':
      return l10n.apprCannotDecideOwn;
    case 'apprTooEarlyCheckin':
      return l10n.ruleTooEarlyCheckin;
    // An OT reject with no reason (#49).
    case 'apprReasonRequired':
      return l10n.apprReasonRequired;
    case 'offsiteApproveCheckinFirst':
      return l10n.apprApproveCheckinFirst;
    case 'offsiteCheckinNotApproved':
      return l10n.apprCheckinNotApproved;
    // Off-site withdrawal — §9's one refusal, raised by the same datasource.
    case 'offsiteCannotCancel':
      return l10n.offsiteCannotCancel;
    // A refused upload (`core/upload/data/upload_error_code.dart`).
    case 'uploadFileTooLarge':
      return l10n.uploadFileTooLarge;
    case 'uploadInvalidFile':
      return l10n.uploadInvalidFile;
    case 'uploadStorageUnavailable':
      return l10n.uploadStorageUnavailable;
    case 'uploadPermissionDenied':
      return l10n.uploadPermissionDenied;
    // The profile photo's own refusals (#59).
    case 'profilePhotoNotImage':
      return l10n.profilePhotoNotImage;
    case 'profilePhotoTooLarge':
      return l10n.profilePhotoTooLarge;

    // Leave (time-off) business rules — the leave datasource encodes a
    // recognised `error.code` as one of these tokens
    // (see `time_off/data/datasources/leave_error_code.dart`).
    case 'leavePendingRequestExists':
      return l10n.leavePendingRequestExists;
    case 'leaveOverlapping':
      return l10n.leaveOverlapping;
    case 'leaveInsufficientBalance':
      return l10n.leaveInsufficientBalance;
    case 'leaveStepChanged':
      return l10n.leaveStepChanged;
    case 'leaveNotApprover':
      return l10n.leaveNotApprover;
    case 'leaveInvalidStatus':
      return l10n.leaveInvalidStatus;
    case 'leaveEmployeeNotFound':
      return l10n.leaveEmployeeNotFound;
    case 'leaveChanged':
      return l10n.leaveChanged;
    case 'leaveRequestGone':
      return l10n.leaveRequestGone;
    case 'offsiteRequestGone':
      return l10n.apprRequestNotFound;
    // "Forgot to scan" requests (#45), from the attendance datasource
    // (`CorrectionErrorCode`): the off-site ones' texts say the same thing.
    case 'correctionRequestGone':
      return l10n.apprRequestNotFound;
    case 'correctionCannotCancel':
      return l10n.offsiteCannotCancel;
    case 'leaveRequiresAttachmentBlocked':
      return l10n.leaveRequiresAttachmentBlocked;
    case 'leaveStartedContactHr':
      return l10n.leaveStartedContactHr;
    // Overtime business rules: the OT data source encodes a recognised
    // `error.code` as one of these tokens
    // (`overtime/data/datasources/ot_error_code.dart`).
    case 'otDisabled':
      return l10n.otDisabled;
    case 'otNotEligible':
      return l10n.otNotEligible;
    case 'otTooFarBack':
      return l10n.otTooFarBack;
    case 'otOverlap':
      return l10n.otOverlap;
    case 'otOverlapsShift':
      return l10n.otOverlapsShift;
    case 'otEmployeeLeft':
      return l10n.otEmployeeLeft;
    case 'otAlreadyDecided':
      return l10n.otAlreadyDecided;
    case 'otAnnounced':
      return l10n.otAnnounced;
    case 'otFull':
      return l10n.otFull;
    case 'otJoinClosed':
      return l10n.otJoinClosed;
    case 'otStepChanged':
      return l10n.otStepChanged;
    case 'otStarted':
      return l10n.otStarted;
    case 'otAlreadyPaid':
      return l10n.otAlreadyPaid;
    case 'otPaidByHand':
      return l10n.otPaidByHand;
    // The same words as for leave.
    case 'otNotApprover':
      return l10n.leaveNotApprover;
    case 'otCancelForbidden':
      return l10n.otCancelForbidden;
    // Salary history — raised by the payroll datasource when the PDF
    // endpoint answers with something that isn't a PDF.
    case 'salaryPdfInvalid':
      return l10n.salaryPdfInvalid;
    default:
      return null;
  }
}

/// Backend error codes from [ApiErrorCodes]: the auth routes (auth.md) and the
/// company, session, permission and module codes any route can answer with.
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
    case ApiErrorCodes.missingToken:
    case ApiErrorCodes.invalidTokenFormat:
    case ApiErrorCodes.invalidTokenType:
    case ApiErrorCodes.missingTenant:
      return l10n.sessionExpired;
    case ApiErrorCodes.subdomainRequired:
      return l10n.errorWrongServer;
    case ApiErrorCodes.tenantNotFound:
      return l10n.errorTenantNotFound;
    case ApiErrorCodes.tenantInactive:
      return l10n.errorTenantInactive;
    case ApiErrorCodes.tenantLookupFailed:
    case ApiErrorCodes.tenantUnavailable:
      return l10n.errorTenantUnavailable;
    case ApiErrorCodes.tenantMismatch:
      return l10n.errorTenantMismatch;
    case ApiErrorCodes.forbidden:
      return l10n.accessForbidden;
    case ApiErrorCodes.moduleNotActive:
      return l10n.errorModuleNotActive;
    case ApiErrorCodes.rateLimited:
      return l10n.errorRateLimited;
    case ApiErrorCodes.employeeNotFound:
      return l10n.ruleEmployeeNotFound;
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

/// A refused "forgot to scan" (#43), with the times or dates it names: the
/// token, then its values after `|` (attendance's `CorrectionErrorCode`).
String? _byCorrection(AppLocalizations l10n, String message) {
  final parts = message.split('|');
  String at(int i) => i + 1 < parts.length ? parts[i + 1] : '';
  return switch (parts.first) {
    'correctionDuplicate' => l10n.attCorrectionDuplicate,
    'correctionTooEarly' => l10n.attCorrectionTooEarly(at(0)),
    'correctionOutOfRange' => l10n.attCorrectionOutOfRange(at(0), at(1)),
    'correctionInvalid' => l10n.attCorrectionInvalid,
    _ => null,
  };
}
