import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_response.dart';

/// What `POST /attendance/correction-requests` refuses with (#43), as tokens
/// `failure_localizer.dart` says in plain words.
///
/// Some refusals carry the times or dates the text names (`details`). They
/// travel inside the token, after [_separator], so the failure stays a plain
/// `Failure.validation`: [encode] puts them in, [decode] takes them out.
class CorrectionErrorCode {
  const CorrectionErrorCode._();

  static const String tokenDuplicate = 'correctionDuplicate';
  static const String tokenTooEarly = 'correctionTooEarly';
  static const String tokenOutOfRange = 'correctionOutOfRange';
  static const String tokenInvalid = 'correctionInvalid';

  /// `GET correction-requests/:id` answered 404: gone, or not the caller's
  /// to see (#45). Said with #37's "this request is not available".
  static const String tokenRequestGone = 'correctionRequestGone';

  /// `PUT correction-requests/:id/cancel` answered `CANNOT_CANCEL`: not the
  /// caller's, or no longer pending (#45). Said with #42's "already decided".
  static const String tokenCannotCancel = 'correctionCannotCancel';

  /// The wire code of that refusal.
  static const String cannotCancel = 'CANNOT_CANCEL';

  static const String _separator = '|';

  static String encode(String token, [List<String> values = const []]) =>
      [token, ...values].join(_separator);

  /// The token and its values, or null when [message] is not one of these.
  static ({String token, List<String> values})? decode(String message) {
    final parts = message.split(_separator);
    const tokens = {
      tokenDuplicate,
      tokenTooEarly,
      tokenOutOfRange,
      tokenInvalid,
    };
    if (!tokens.contains(parts.first)) return null;
    return (token: parts.first, values: parts.sublist(1));
  }

  /// The failure a refused submit stands for, or null when it is none of
  /// these (no signal, a 500, `EMPLOYEE_NOT_FOUND`: the shared handling).
  static Failure? fromResponse(DioException error) {
    final data = error.response?.data;
    final apiError = ApiError.tryParse(data);
    final code = apiError?.code;
    final details = _details(data);
    final status = error.response?.statusCode;
    switch (code) {
      case 'DUPLICATE':
        return Failure.validation(message: encode(tokenDuplicate), code: code);
      // Without the time or the dates it names, the general text: never a
      // sentence with a blank in it.
      case 'TOO_EARLY_CHECKIN':
        final opens = _hhmm(details['clock_in_opens']);
        return Failure.validation(
          message: opens.isEmpty
              ? encode(tokenInvalid)
              : encode(tokenTooEarly, [opens]),
          code: code,
        );
      case 'CORRECTION_DATE_OUT_OF_RANGE':
        final earliest = _text(details['earliest_date']);
        final latest = _text(details['latest_date']);
        return Failure.validation(
          message: earliest.isEmpty || latest.isEmpty
              ? encode(tokenInvalid)
              : encode(tokenOutOfRange, [earliest, latest]),
          code: code,
        );
    }
    // Any 422 (VALIDATION_ERROR), with or without a field map: the server
    // names no field the form could point at.
    if (status == 422 || code == 'VALIDATION_ERROR') {
      return Failure.validation(message: encode(tokenInvalid), code: code);
    }
    return null;
  }

  static Map<String, dynamic> _details(dynamic data) {
    final error = data is Map ? data['error'] : null;
    final details = error is Map ? error['details'] : null;
    return details is Map ? details.cast<String, dynamic>() : const {};
  }

  /// A value as text, with the separator taken out so it cannot shift the
  /// values after it.
  static String _text(dynamic value) =>
      value is String ? value.replaceAll(_separator, '').trim() : '';

  /// `07:45` from `07:45`, `07:45:00` or a full `…T07:45:00` date-time; empty
  /// when there is no time in it.
  static String _hhmm(dynamic value) {
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(_text(value));
    return match?[1] ?? '';
  }
}
