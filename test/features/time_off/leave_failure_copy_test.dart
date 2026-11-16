import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  /// Each token the leave data source puts in a `Failure.validation`
  /// message, with the Lao text it must show.
  const laoByToken = {
    'leavePendingRequestExists':
        'ທ່ານມີຄຳຮ້ອງລາທີ່ລໍຖ້າອະນຸມັດຢູ່ແລ້ວ ກະລຸນາລໍຖ້າໃຫ້ແລ້ວກ່ອນ.',
    'leaveOverlapping': 'ວັນທີ່ເລືອກຊ້ອນກັບຄຳຮ້ອງລາອື່ນ.',
    'leaveInsufficientBalance': 'ວັນລາຄົງເຫຼືອບໍ່ພຽງພໍສຳລັບວັນທີ່ເລືອກ.',
    'leaveStepChanged': 'ຄຳຮ້ອງນີ້ຫາກໍ່ຖືກອັບເດດ — ກະລຸນາກວດຄືນ.',
    'leaveNotApprover': 'ທ່ານບໍ່ມີສິດອະນຸມັດຂັ້ນຕອນນີ້.',
    'leaveInvalidStatus': 'ຄຳຮ້ອງນີ້ບໍ່ສາມາດປ່ຽນແປງໄດ້ອີກຕໍ່ໄປ.',
    'leaveEmployeeNotFound': 'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ເຊື່ອມກັບຂໍ້ມູນພະນັກງານ.',
  };

  test('the seven tokens here are the seven the data source produces', () {
    expect(
      LeaveErrorCode.tokenByWire.values.toSet(),
      laoByToken.keys.toSet(),
    );
  });

  for (final MapEntry(key: token, value: text) in laoByToken.entries) {
    test('$token gives its Lao text through localize', () {
      expect(Failure.validation(message: token).localize(lo), text);
    });
  }

  test('each token has English text too, and it is not the token itself', () {
    for (final token in laoByToken.keys) {
      final text = Failure.validation(message: token).localize(en);

      expect(text, isNot(token), reason: token);
      expect(RegExp(r'[຀-໿]').hasMatch(text), isFalse, reason: token);
    }
  });

  test('the token wins over a server code on the same failure', () {
    expect(
      const Failure.validation(
        message: 'leaveNotApprover',
        code: 'FORBIDDEN',
      ).localize(lo),
      laoByToken['leaveNotApprover'],
    );
  });

  test('a message that is not a token is shown as it is', () {
    expect(
      const Failure.validation(message: 'Leave changed').localize(lo),
      'Leave changed',
    );
  });
}
