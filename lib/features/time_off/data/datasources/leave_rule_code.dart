import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_response.dart';

/// The leave type's own rules, as `POST /leave/requests` and
/// `PUT /leave/requests/:id` refuse with them (live 18 Nov 2026,
/// Nexton-Backend#192), as tokens `failure_localizer.dart` says in plain
/// words.
///
/// Three refusals carry the date or the numbers the text names
/// (`error.details`). They travel inside the token, after [_separator], so
/// the failure stays a plain `Failure.validation`: the same way
/// attendance's `CorrectionErrorCode` does it.
class LeaveRuleCode {
  const LeaveRuleCode._();

  static const String tokenTypeInactive = 'leaveRuleTypeInactive';
  static const String tokenTypeNotFound = 'leaveRuleTypeNotFound';
  static const String tokenGenderNotAllowed = 'leaveRuleGenderNotAllowed';
  static const String tokenGenderNotSet = 'leaveRuleGenderNotSet';
  static const String tokenNotYetAvailable = 'leaveRuleNotYetAvailable';
  static const String tokenHalfDayNotAllowed = 'leaveRuleHalfDayNotAllowed';
  static const String tokenNoticeTooShort = 'leaveRuleNoticeTooShort';
  static const String tokenTooLong = 'leaveRuleTooLong';
  static const String tokenSpanTooLong = 'leaveRuleSpanTooLong';

  static const String _separator = '|';

  /// The server's general "invalid" code. A leave type that was deleted (or
  /// an id that is no type) is refused with it and the message
  /// [_typeNotFoundMessage]: that refusal has no code of its own.
  static const String validationError = 'VALIDATION_ERROR';
  static const String _typeNotFoundMessage = 'leave type not found';

  static const Set<String> _tokens = {
    tokenTypeInactive,
    tokenTypeNotFound,
    tokenGenderNotAllowed,
    tokenGenderNotSet,
    tokenNotYetAvailable,
    tokenHalfDayNotAllowed,
    tokenNoticeTooShort,
    tokenTooLong,
    tokenSpanTooLong,
  };

  /// The failure a refused new request or edit stands for, or null when it
  /// is none of these rules (the older codes, no signal, a 500, a rule this
  /// App does not know: all left to the handling they already have).
  ///
  /// A rule whose date or numbers are missing or unreadable gives its token
  /// alone, which reads as the rule's general sentence: never a sentence
  /// with a blank in it.
  static Failure? fromResponse(DioException error) {
    final data = error.response?.data;
    final apiError = ApiError.tryParse(data);
    final code = apiError?.code;
    final details = _details(data);

    final String? message;
    switch (code) {
      case 'LEAVE_TYPE_INACTIVE':
        message = tokenTypeInactive;
      case 'LEAVE_GENDER_NOT_ALLOWED':
        message = tokenGenderNotAllowed;
      case 'LEAVE_GENDER_NOT_SET':
        message = tokenGenderNotSet;
      case 'LEAVE_HALF_DAY_NOT_ALLOWED':
        message = tokenHalfDayNotAllowed;
      case 'LEAVE_SPAN_TOO_LONG':
        message = tokenSpanTooLong;
      case 'LEAVE_NOT_YET_AVAILABLE':
        message = _encode(tokenNotYetAvailable, [
          _date(details['available_from']),
        ]);
      case 'LEAVE_NOTICE_TOO_SHORT':
        message = _encode(tokenNoticeTooShort, [
          _number(details['min_notice_days']),
          _date(details['earliest_start_date']),
        ]);
      case 'LEAVE_TOO_LONG':
        message = _encode(tokenTooLong, [
          _number(details['max_days']),
          _number(details['requested_days']),
        ]);
      case validationError:
        message = _isTypeNotFound(apiError?.message)
            ? tokenTypeNotFound
            : null;
      default:
        message = null;
    }
    return message == null
        ? null
        : Failure.validation(message: message, code: code);
  }

  /// The rule token [failure] carries, under any values, or null when it
  /// carries none.
  static String? tokenOf(Failure failure) => failure.maybeWhen(
    validation: (message, _, _) {
      final token = message.split(_separator).first;
      return _tokens.contains(token) ? token : null;
    },
    orElse: () => null,
  );

  /// Refusals after which the leave type list is asked for again, so the
  /// form offers what can still be picked: the type was switched off, or is
  /// gone. Any other `VALIDATION_ERROR` reloads it too: that one has only
  /// its message to go by, and asking again costs one small call.
  static bool reloadsTypes(Failure failure) {
    final token = tokenOf(failure);
    if (token == tokenTypeInactive || token == tokenTypeNotFound) return true;
    return failure.maybeWhen(
      validation: (_, _, code) => code == validationError,
      orElse: () => false,
    );
  }

  static bool _isTypeNotFound(String? message) {
    final text = (message ?? '').trim().toLowerCase();
    return text == _typeNotFoundMessage || text == '$_typeNotFoundMessage.';
  }

  /// The token with its values, or the token alone when any value is empty.
  static String _encode(String token, List<String> values) =>
      values.any((value) => value.isEmpty)
      ? token
      : [token, ...values].join(_separator);

  static Map<String, dynamic> _details(dynamic data) {
    final error = data is Map ? data['error'] : null;
    final details = error is Map ? error['details'] : null;
    return details is Map ? details.cast<String, dynamic>() : const {};
  }

  /// `05/03/2027` from `2027-03-05` or a date-time that starts with it: the
  /// calendar day as the server wrote it, never shifted by a time zone.
  /// Empty when it is not a real date.
  static String _date(dynamic value) {
    if (value is! String) return '';
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value.trim());
    if (match == null) return '';
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // `2027-13-45` rolls over into another day: not a date the server meant.
    if (date.year != year || date.month != month || date.day != day) return '';
    return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
  }

  /// A day count as text: `5` for 5 or 5.0, `7.5` for a half. Read from a
  /// number or from a number sent as text; empty for anything else.
  static String _number(dynamic value) {
    final number = switch (value) {
      num n => n,
      String s => num.tryParse(s.trim()),
      _ => null,
    };
    if (number == null || !number.isFinite || number < 0) return '';
    final text = number.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
