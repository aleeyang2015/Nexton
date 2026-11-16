import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  const sessionExpired = 'ເຊສຊັນຂອງທ່ານໝົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.';
  const unavailable =
      'ລະບົບຂອງບໍລິສັດຍັງບໍ່ພ້ອມ. ກະລຸນາລອງໃໝ່ໃນອີກບໍ່ເທົ່າໃດນາທີ.';

  /// Every code in issue #4's table, as the failure [ApiErrorMapper] builds
  /// for its status, with the Lao text it must show.
  final table = <String, (Failure, String)>{
    'SUBDOMAIN_REQUIRED': (
      const Failure.auth(message: 'server', code: 'SUBDOMAIN_REQUIRED'),
      'ແອັບນີ້ເຊື່ອມຕໍ່ຜິດບ່ອນ. ກະລຸນາອັບເດດແອັບ.',
    ),
    'TENANT_NOT_FOUND': (
      const Failure.network(
        message: 'server',
        statusCode: 404,
        errorCode: 'TENANT_NOT_FOUND',
      ),
      'ບໍ່ພົບບໍລິສັດນີ້ໃນລະບົບ.',
    ),
    'TENANT_INACTIVE': (
      const Failure.auth(message: 'server', code: 'TENANT_INACTIVE'),
      'ບໍລິສັດຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ HR.',
    ),
    'TENANT_LOOKUP_FAILED': (
      const Failure.server(
        message: 'server',
        statusCode: 503,
        errorCode: 'TENANT_LOOKUP_FAILED',
      ),
      unavailable,
    ),
    'TENANT_UNAVAILABLE': (
      const Failure.server(
        message: 'server',
        statusCode: 503,
        errorCode: 'TENANT_UNAVAILABLE',
      ),
      unavailable,
    ),
    'TENANT_MISMATCH': (
      const Failure.validation(message: 'server', code: 'TENANT_MISMATCH'),
      'ບັນຊີນີ້ເປັນຂອງບໍລິສັດອື່ນ. ກະລຸນາອອກຈາກລະບົບ ແລ້ວເຂົ້າໃໝ່.',
    ),
    'MISSING_TENANT': (
      const Failure.validation(message: 'server', code: 'MISSING_TENANT'),
      sessionExpired,
    ),
    'MISSING_TOKEN': (
      const Failure.auth(message: 'server', code: 'MISSING_TOKEN'),
      sessionExpired,
    ),
    'INVALID_TOKEN_FORMAT': (
      const Failure.auth(message: 'server', code: 'INVALID_TOKEN_FORMAT'),
      sessionExpired,
    ),
    'INVALID_TOKEN_TYPE': (
      const Failure.auth(message: 'server', code: 'INVALID_TOKEN_TYPE'),
      sessionExpired,
    ),
    'INVALID_TOKEN': (
      const Failure.auth(message: 'server', code: 'INVALID_TOKEN'),
      sessionExpired,
    ),
    'SESSION_EXPIRED': (
      const Failure.auth(message: 'server', code: 'SESSION_EXPIRED'),
      sessionExpired,
    ),
    'FORBIDDEN': (
      const Failure.validation(message: 'server', code: 'FORBIDDEN'),
      'ບໍ່ໄດ້ຮັບອະນຸຍາດເຂົ້າເຖິງ.',
    ),
    'MODULE_NOT_ACTIVE': (
      const Failure.validation(message: 'server', code: 'MODULE_NOT_ACTIVE'),
      'ບໍລິສັດຂອງທ່ານຍັງບໍ່ໄດ້ເປີດໃຊ້ສ່ວນນີ້.',
    ),
    'RATE_LIMITED': (
      const Failure.network(
        message: 'server',
        statusCode: 429,
        errorCode: 'RATE_LIMITED',
      ),
      'ສົ່ງຄຳຂໍຖີ່ເກີນໄປ. ກະລຸນາລໍຖ້າໜຶ່ງນາທີ ແລ້ວລອງໃໝ່.',
    ),
    'EMPLOYEE_NOT_FOUND': (
      const Failure.validation(message: 'server', code: 'EMPLOYEE_NOT_FOUND'),
      'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ຜູກກັບຂໍ້ມູນພະນັກງານ. ກະລຸນາຕິດຕໍ່ HR.',
    ),
  };

  group('codes in the shared table', () {
    for (final MapEntry(key: code, value: (failure, text)) in table.entries) {
      test('$code shows its Lao text', () {
        expect(failure.localize(lo), text);
      });
    }

    test('English has its own text for a new code', () {
      expect(
        const Failure.validation(
          message: 'server',
          code: 'MODULE_NOT_ACTIVE',
        ).localize(en),
        'Your company has not turned this on.',
      );
    });
  });

  group('a code the App does not know', () {
    test('a refusal shows the server message', () {
      expect(
        const Failure.validation(
          message: 'Shift is locked for payroll',
          code: 'SHIFT_LOCKED',
        ).localize(lo),
        'Shift is locked for payroll',
      );
    });

    test('an auth failure shows the server message', () {
      expect(
        const Failure.auth(message: 'Odd one', code: 'ODD').localize(lo),
        'Odd one',
      );
    });
  });

  test('a client rule token still wins over a code', () {
    // The feature datasources put a token in the message; the localizer must
    // keep reading it first.
    expect(
      const Failure.validation(
        message: 'leaveNotApprover',
        code: 'FORBIDDEN',
      ).localize(lo),
      lo.leaveNotApprover,
    );
  });
}
