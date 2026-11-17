import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// Every OT refusal in plain Lao (and English), the same words on every OT
/// screen.
void main() {
  final lo = AppLocalizationsLo();
  final en = AppLocalizationsEn();

  String say(String token, {bool lao = true}) =>
      Failure.validation(message: token).localize(lao ? lo : en);

  const lao = {
    OtErrorCode.tokenDisabled: 'ບໍລິສັດຍັງບໍ່ໄດ້ເປີດໃຊ້ໂອທີ.',
    OtErrorCode.tokenNotEligible:
        'ທ່ານຍັງບໍ່ມີສິດຂໍໂອທີ. ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ.',
    OtErrorCode.tokenTooFarBack: 'ວັນທີນີ້ຍ້ອນຫຼັງເກີນກວ່າທີ່ບໍລິສັດອະນຸຍາດ.',
    OtErrorCode.tokenOverlap: 'ເວລານີ້ທັບກັບໂອທີອື່ນຂອງທ່ານ.',
    OtErrorCode.tokenOverlapsShift:
        'ເວລານີ້ທັບກັບກະວຽກຂອງທ່ານ. ໂອທີຕ້ອງຢູ່ນອກກະວຽກ.',
    OtErrorCode.tokenEmployeeLeft:
        'ຂໍໂອທີວັນນີ້ບໍ່ໄດ້. ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ.',
    OtErrorCode.tokenAlreadyDecided:
        'ຄຳຂໍນີ້ມີການຕັດສິນແລ້ວ, ປ່ຽນບໍ່ໄດ້. ກະລຸນາຖາມຜູ້ອະນຸມັດ ຫຼື ຝ່າຍບຸກຄະລາກອນ.',
    OtErrorCode.tokenAnnounced:
        'ໂອທີນີ້ມາຈາກປະກາດຂອງຝ່າຍບຸກຄະລາກອນ, ແກ້ເວລາບໍ່ໄດ້. ຖ້າບໍ່ໄປ ໃຫ້ຍົກເລີກ.',
    OtErrorCode.tokenFull: 'ບ່ອນເຕັມແລ້ວ.',
    OtErrorCode.tokenJoinClosed: 'ປິດຮັບແລ້ວ.',
    OtErrorCode.tokenStepChanged: 'ຄຳຂໍນີ້ຫາກໍ່ຖືກອັບເດດ — ກະລຸນາກວດຄືນ.',
    OtErrorCode.tokenStarted:
        'ໂອທີນີ້ເລີ່ມແລ້ວ. ມີແຕ່ຝ່າຍບຸກຄະລາກອນທີ່ຍົກເລີກໄດ້.',
    OtErrorCode.tokenAlreadyPaid:
        'ເງິນເດືອນທີ່ອະນຸມັດແລ້ວໄດ້ຈ່າຍໂອທີນີ້, ຍົກເລີກບໍ່ໄດ້.',
    OtErrorCode.tokenPaidByHand:
        'ຝ່າຍບຸກຄະລາກອນໝາຍວ່າຈ່າຍເງິນສົດແລ້ວ. ກະລຸນາຖາມຝ່າຍບຸກຄະລາກອນ.',
    OtErrorCode.tokenNotApprover: 'ທ່ານບໍ່ມີສິດອະນຸມັດຂັ້ນຕອນນີ້.',
    OtErrorCode.tokenCancelForbidden: 'ຄຳຂໍທີ່ລໍຖ້າ ໃຫ້ກົດປະຕິເສດແທນ.',
  };

  const english = {
    OtErrorCode.tokenDisabled: 'Your company has not turned on OT.',
    OtErrorCode.tokenNotEligible: 'You may not ask for OT yet. Please contact HR.',
    OtErrorCode.tokenTooFarBack:
        'This date is further back than your company allows.',
    OtErrorCode.tokenOverlap: 'This time overlaps another OT of yours.',
    OtErrorCode.tokenOverlapsShift:
        'This time overlaps your shift. OT must be outside your shift.',
    OtErrorCode.tokenEmployeeLeft:
        'OT cannot be asked for this date. Please contact HR.',
    OtErrorCode.tokenAlreadyDecided:
        'This request is already decided and cannot change. Ask your approver or HR.',
    OtErrorCode.tokenAnnounced:
        'This OT is from an HR post; its time cannot change. Cancel it if you cannot come.',
    OtErrorCode.tokenFull: 'All places are taken.',
    OtErrorCode.tokenJoinClosed: 'Joining is closed.',
    OtErrorCode.tokenStepChanged: 'This request just changed — please check again.',
    OtErrorCode.tokenStarted: 'This OT has started. Only HR can cancel it.',
    OtErrorCode.tokenAlreadyPaid:
        'An approved payroll already pays this OT; it cannot be cancelled.',
    OtErrorCode.tokenPaidByHand: 'HR marked this OT as paid in cash. Please ask HR.',
    OtErrorCode.tokenNotApprover: "You can't approve this step.",
    OtErrorCode.tokenCancelForbidden: 'A waiting request: reject it instead.',
  };

  test('every OT token has its Lao and English text', () {
    expect(lao.keys.toSet(), OtErrorCode.allTokens);
    for (final MapEntry(key: token, value: text) in lao.entries) {
      expect(say(token), text, reason: token);
    }
    for (final MapEntry(key: token, value: text) in english.entries) {
      expect(say(token, lao: false), text, reason: token);
    }
  });

  test('NOT_APPROVER uses the leave wording, word for word', () {
    expect(say(OtErrorCode.tokenNotApprover), lo.leaveNotApprover);
  });

  test('EMPLOYEE_NOT_FOUND kept as a code shows #4\'s shared text', () {
    const failure = Failure.validation(
      message: 'employee not found',
      code: ApiErrorCodes.employeeNotFound,
    );

    expect(failure.localize(lo), lo.ruleEmployeeNotFound);
  });

  test('a code the App does not know shows the server\'s message', () {
    const failure = Failure.validation(
      message: 'Something new happened',
      code: 'OT_SOMETHING_NEW',
    );

    expect(failure.localize(lo), 'Something new happened');
  });
}
