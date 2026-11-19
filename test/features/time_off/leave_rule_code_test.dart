import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/features/time_off/data/datasources/leave_rule_code.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

/// The leave type's own rules (live 18 Nov 2026): what the server refuses
/// with, the token each becomes, and the words it is said in.
void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  DioException refusal(
    int status,
    String code, {
    Object? details,
    String message = 'server english',
  }) {
    final options = RequestOptions(path: '/core_hr/leave/requests');
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: {
          'success': false,
          'error': {'code': code, 'message': message, 'details': ?details},
        },
      ),
    );
  }

  String? messageOf(DioException error) =>
      LeaveRuleCode.fromResponse(error)?.message;

  group('the code becomes its token', () {
    test('the five rules that name nothing', () {
      expect(
        messageOf(refusal(422, 'LEAVE_TYPE_INACTIVE')),
        'leaveRuleTypeInactive',
      );
      expect(
        messageOf(refusal(422, 'LEAVE_GENDER_NOT_ALLOWED')),
        'leaveRuleGenderNotAllowed',
      );
      expect(
        messageOf(refusal(422, 'LEAVE_GENDER_NOT_SET')),
        'leaveRuleGenderNotSet',
      );
      expect(
        messageOf(refusal(422, 'LEAVE_HALF_DAY_NOT_ALLOWED')),
        'leaveRuleHalfDayNotAllowed',
      );
      expect(
        messageOf(refusal(400, 'LEAVE_SPAN_TOO_LONG')),
        'leaveRuleSpanTooLong',
      );
    });

    test('the failure keeps the server\'s code', () {
      final failure = LeaveRuleCode.fromResponse(
        refusal(422, 'LEAVE_TYPE_INACTIVE'),
      );

      expect(
        failure,
        isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          'LEAVE_TYPE_INACTIVE',
        ),
      );
    });

    test('not yet available: the date it opens, day first', () {
      expect(
        messageOf(
          refusal(
            422,
            'LEAVE_NOT_YET_AVAILABLE',
            details: {'available_from': '2027-03-05'},
          ),
        ),
        'leaveRuleNotYetAvailable|05/03/2027',
      );
      // A full date-time is still that calendar day.
      expect(
        messageOf(
          refusal(
            422,
            'LEAVE_NOT_YET_AVAILABLE',
            details: {'available_from': '2027-03-05T00:00:00Z'},
          ),
        ),
        'leaveRuleNotYetAvailable|05/03/2027',
      );
    });

    test('notice too short: the days and the earliest first day', () {
      expect(
        messageOf(
          refusal(
            422,
            'LEAVE_NOTICE_TOO_SHORT',
            details: {
              'min_notice_days': 3,
              'earliest_start_date': '2026-11-23',
            },
          ),
        ),
        'leaveRuleNoticeTooShort|3|23/11/2026',
      );
    });

    test('too long: the most days allowed, halves kept; what was asked is '
        'not said', () {
      expect(
        messageOf(
          refusal(
            422,
            'LEAVE_TOO_LONG',
            details: {'max_days': 5, 'requested_days': 3},
          ),
        ),
        'leaveRuleTooLong|5',
      );
      expect(
        messageOf(refusal(422, 'LEAVE_TOO_LONG', details: {'max_days': 2.5})),
        'leaveRuleTooLong|2.5',
      );
      // A number sent as text, and a whole number sent with a decimal.
      expect(
        messageOf(refusal(422, 'LEAVE_TOO_LONG', details: {'max_days': '5.0'})),
        'leaveRuleTooLong|5',
      );
    });

    test('a value that is missing or of the wrong kind: the token alone, '
        'never half a sentence', () {
      for (final details in <Object?>[
        null,
        'oops',
        <String, dynamic>{},
        {'available_from': 'soon'},
        {'available_from': '2027-13-45'},
        {'available_from': 12},
      ]) {
        expect(
          messageOf(refusal(422, 'LEAVE_NOT_YET_AVAILABLE', details: details)),
          'leaveRuleNotYetAvailable',
          reason: '$details',
        );
      }
      // One of the two is not enough.
      expect(
        messageOf(
          refusal(422, 'LEAVE_NOTICE_TOO_SHORT', details: {'min_notice_days': 3}),
        ),
        'leaveRuleNoticeTooShort',
      );
      // Not a count of days a sentence could name.
      for (final max in <Object?>['many', 0, -2, '0x1F', 1e21, '5|9', true]) {
        expect(
          messageOf(refusal(422, 'LEAVE_TOO_LONG', details: {'max_days': max})),
          'leaveRuleTooLong',
          reason: '$max',
        );
      }
      expect(
        messageOf(
          refusal(
            422,
            'LEAVE_NOTICE_TOO_SHORT',
            details: {
              'min_notice_days': 0,
              'earliest_start_date': '2026-11-23',
            },
          ),
        ),
        'leaveRuleNoticeTooShort',
      );
      // An empty date (year 1) and a date with a digit too many.
      for (final date in ['0001-01-01T00:00:00Z', '2026-11-234']) {
        expect(
          messageOf(
            refusal(
              422,
              'LEAVE_NOT_YET_AVAILABLE',
              details: {'available_from': date},
            ),
          ),
          'leaveRuleNotYetAvailable',
          reason: date,
        );
      }
    });

    test('"leave type not found" has no code of its own: told by its '
        'message on a VALIDATION_ERROR', () {
      expect(
        messageOf(
          refusal(400, 'VALIDATION_ERROR', message: 'leave type not found'),
        ),
        'leaveRuleTypeNotFound',
      );
      expect(
        messageOf(
          refusal(400, 'VALIDATION_ERROR', message: ' Leave type not found. '),
        ),
        'leaveRuleTypeNotFound',
      );
    });

    test('anything else is not a rule: left to the shared handling', () {
      expect(
        LeaveRuleCode.fromResponse(
          refusal(400, 'VALIDATION_ERROR', message: 'reason is required'),
        ),
        isNull,
      );
      expect(LeaveRuleCode.fromResponse(refusal(422, 'A_NEW_RULE')), isNull);
      expect(
        LeaveRuleCode.fromResponse(refusal(409, 'OVERLAPPING_LEAVE')),
        isNull,
      );
      expect(
        LeaveRuleCode.fromResponse(
          DioException(requestOptions: RequestOptions(path: '/x')),
        ),
        isNull,
      );
    });
  });

  group('the words', () {
    const laoByMessage = {
      'leaveRuleTypeInactive':
          'ປະເພດການລານີ້ຖືກປິດໃຊ້ງານແລ້ວ ກະລຸນາເລືອກປະເພດອື່ນ.',
      'leaveRuleTypeNotFound': 'ບໍ່ພົບປະເພດການລານີ້ແລ້ວ ກະລຸນາເລືອກປະເພດອື່ນ.',
      'leaveRuleGenderNotAllowed': 'ປະເພດການລານີ້ບໍ່ສາມາດໃຊ້ກັບເພດຂອງທ່ານໄດ້.',
      'leaveRuleGenderNotSet':
          'ຂໍ້ມູນພະນັກງານຂອງທ່ານຍັງບໍ່ໄດ້ລະບຸເພດ ກະລຸນາຕິດຕໍ່ HR ເພື່ອລະບຸ.',
      'leaveRuleNotYetAvailable':
          'ທ່ານຍັງບໍ່ສາມາດໃຊ້ປະເພດການລານີ້ໄດ້ ກະລຸນາສອບຖາມ HR.',
      'leaveRuleNotYetAvailable|05/03/2027':
          'ປະເພດການລານີ້ໃຊ້ໄດ້ສຳລັບວັນລາຕັ້ງແຕ່ວັນທີ 05/03/2027 ເປັນຕົ້ນໄປ.',
      'leaveRuleHalfDayNotAllowed': 'ປະເພດການລານີ້ບໍ່ສາມາດລາເຄິ່ງມື້ໄດ້.',
      'leaveRuleNoticeTooShort': 'ການລາປະເພດນີ້ຕ້ອງຂໍລ່ວງໜ້າຫຼາຍກວ່ານີ້.',
      'leaveRuleNoticeTooShort|3|23/11/2026':
          'ການລາປະເພດນີ້ຕ້ອງຂໍລ່ວງໜ້າຢ່າງໜ້ອຍ 3 ວັນ. '
          'ວັນທຳອິດທີ່ລາໄດ້ແມ່ນ 23/11/2026.',
      'leaveRuleTooLong':
          'ຈຳນວນວັນລາຕິດຕໍ່ກັນເກີນກວ່າທີ່ປະເພດການລານີ້ອະນຸຍາດ. '
          'ວັນພັກທີ່ຢູ່ລະຫວ່າງກາງກໍນັບລວມ.',
      'leaveRuleTooLong|5':
          'ປະເພດການລານີ້ລາຕິດຕໍ່ກັນໄດ້ສູງສຸດ 5 ວັນ. '
          'ວັນພັກທີ່ຢູ່ລະຫວ່າງກາງກໍນັບລວມ.',
      'leaveRuleSpanTooLong':
          'ວັນທຳອິດ ແລະ ວັນສຸດທ້າຍຂອງຄຳຮ້ອງດຽວຕ້ອງຫ່າງກັນບໍ່ເກີນ 1 ປີ.',
    };

    for (final MapEntry(key: message, value: text) in laoByMessage.entries) {
      test('$message in Lao', () {
        expect(Failure.validation(message: message).localize(lo), text);
      });
    }

    test('each has English text too, with its values in it', () {
      for (final message in laoByMessage.keys) {
        final text = Failure.validation(message: message).localize(en);

        expect(text, isNot(message), reason: message);
        expect(text.contains('|'), isFalse, reason: message);
        expect(RegExp(r'[຀-໿]').hasMatch(text), isFalse, reason: message);
        for (final value in message.split('|').skip(1)) {
          expect(text, contains(value), reason: message);
        }
      }
    });

    test('the English sentences with values, word for word: each value '
        'in its own place', () {
      String say(String message) =>
          Failure.validation(message: message).localize(en);

      expect(
        say('leaveRuleNotYetAvailable|05/03/2027'),
        'This leave type can be used for leave days from 05/03/2027 onwards.',
      );
      expect(
        say('leaveRuleNoticeTooShort|3|23/11/2026'),
        'This leave type needs 3 day(s) of notice. '
        'The earliest first day is 23/11/2026.',
      );
      expect(
        say('leaveRuleTooLong|5'),
        'This leave type allows at most 5 day(s) in a row. '
        'Days off in between count too.',
      );
    });

    test('a token with the wrong number of values reads as the general '
        'sentence', () {
      expect(
        const Failure.validation(message: 'leaveRuleTooLong|5|7').localize(en),
        en.leaveRuleTooLong,
      );
      expect(
        const Failure.validation(
          message: 'leaveRuleNoticeTooShort|3',
        ).localize(en),
        en.leaveRuleNoticeTooShort,
      );
    });

    test('the token wins over the server\'s code and English message', () {
      expect(
        const Failure.validation(
          message: 'leaveRuleTypeInactive',
          code: 'LEAVE_TYPE_INACTIVE',
        ).localize(lo),
        laoByMessage['leaveRuleTypeInactive'],
      );
    });

    test('a rule the App does not know still shows the server\'s message', () {
      expect(
        const Failure.validation(
          message: 'Leave type needs approval from finance.',
          code: 'A_NEW_RULE',
        ).localize(lo),
        'Leave type needs approval from finance.',
      );
    });
  });

  group('which refusals are about the leave type itself', () {
    test('a type switched off, or gone', () {
      for (final failure in const [
        Failure.validation(message: 'leaveRuleTypeInactive'),
        Failure.validation(message: 'leaveRuleTypeNotFound'),
      ]) {
        expect(
          LeaveRuleCode.isTypeRefused(failure),
          isTrue,
          reason: '$failure',
        );
      }
    });

    test('not the other rules, another VALIDATION_ERROR, nor a failure of '
        'another kind', () {
      for (final failure in const [
        Failure.validation(message: 'leaveRuleTooLong|5'),
        Failure.validation(message: 'leaveRuleGenderNotSet'),
        Failure.validation(message: 'leaveInsufficientBalance'),
        Failure.validation(
          message: 'reason is required',
          code: 'VALIDATION_ERROR',
        ),
        Failure.network(message: 'No internet connection'),
        Failure.server(message: 'boom', statusCode: 500),
      ]) {
        expect(
          LeaveRuleCode.isTypeRefused(failure),
          isFalse,
          reason: '$failure',
        );
      }
    });

    test('tokenOf reads the token under its values', () {
      expect(
        LeaveRuleCode.tokenOf(
          const Failure.validation(message: 'leaveRuleTooLong|5'),
        ),
        'leaveRuleTooLong',
      );
      expect(
        LeaveRuleCode.tokenOf(
          const Failure.validation(message: 'leaveOverlapping'),
        ),
        isNull,
      );
    });
  });
}
