import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// A refused "forgot to scan", in plain words (#43).
void main() {
  final lo = AppLocalizationsLo();
  final en = AppLocalizationsEn();

  DioException refused(int status, String code, [Map? details]) {
    final options = RequestOptions(path: '/attendance/correction-requests');
    return DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: {
          'success': false,
          'error': {
            'code': code,
            'message': 'server english',
            if (details != null) 'details': details,
          },
        },
      ),
    );
  }

  String say(DioException e, {bool lao = true}) =>
      CorrectionErrorCode.fromResponse(e)!.localize(lao ? lo : en);

  test('DUPLICATE: already asked for this day and part', () {
    expect(say(refused(409, 'DUPLICATE')), 'ທ່ານຂໍແກ້ໄຂມື້ ແລະ ຊ່ວງກະນີ້ແລ້ວ');
  });

  test('TOO_EARLY_CHECKIN keeps the opening time', () {
    expect(
      say(refused(409, 'TOO_EARLY_CHECKIN', {'clock_in_opens': '07:45:00'})),
      'ລົງເວລາເຂົ້າຂອງກະນັ້ນເລີ່ມໄດ້ເວລາ 07:45',
    );
  });

  test('CORRECTION_DATE_OUT_OF_RANGE keeps both dates', () {
    expect(
      say(
        refused(422, 'CORRECTION_DATE_OUT_OF_RANGE', {
          'earliest_date': '2026-10-18',
          'latest_date': '2026-11-17',
        }),
        lao: false,
      ),
      'Pick a date from 2026-10-18 to 2026-11-17',
    );
  });

  test(
    'a 422 with no field map still maps: check the date, times and part',
    () {
      expect(
        say(refused(422, 'VALIDATION_ERROR')),
        'ກະລຸນາກວດວັນທີ, ເວລາ ແລະ ຊ່ວງກະອີກຄັ້ງ',
      );
    },
  );

  test('a 500 or EMPLOYEE_NOT_FOUND is left to the shared handling', () {
    expect(CorrectionErrorCode.fromResponse(refused(500, 'INTERNAL')), isNull);
    expect(
      CorrectionErrorCode.fromResponse(refused(400, 'EMPLOYEE_NOT_FOUND')),
      isNull,
    );
  });

  test('an unpacked token is not mistaken for another', () {
    expect(CorrectionErrorCode.decode('leaveChanged'), isNull);
    expect(
      const Failure.validation(
        message: 'correctionTooEarly|07:45',
      ).localize(en),
      'Clock-in for that shift opens at 07:45',
    );
  });
}
