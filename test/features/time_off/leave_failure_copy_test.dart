import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_approvals_state.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_copy.dart';
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
    'leaveChanged':
        'ຄຳຮ້ອງລານີ້ຫາກໍ່ມີການປ່ຽນແປງ. ໂຫຼດຂໍ້ມູນໃໝ່ແລ້ວ, ກະລຸນາກວດເບິ່ງແລ້ວລອງອີກຄັ້ງ.',
    'leaveRequestGone': 'ຄຳຮ້ອງນີ້ບໍ່ມີແລ້ວ ຫຼື ທ່ານບໍ່ມີສິດເບິ່ງ.',
    'leaveStartedContactHr':
        'ການລານີ້ເລີ່ມແລ້ວ ຈຶ່ງຍົກເລີກໃນແອັບບໍ່ໄດ້. ຖ້າຕ້ອງການປ່ຽນ, ກະລຸນາຕິດຕໍ່ HR.',
    // LEAVE_ATTACHMENT_REQUIRED (#39, after Nexton-Backend#192).
    'leaveRequiresAttachmentBlocked':
        'ປະເພດນີ້ຕ້ອງແນບໄຟລ໌ ກະລຸນາແນບໄຟລ໌ກ່ອນສົ່ງ',
  };

  test('the eleven tokens here are the eleven the data source produces', () {
    expect(
      {
        ...LeaveErrorCode.tokenByWire.values,
        // Not in the table: NOT_FOUND means this only on some calls.
        LeaveErrorCode.tokenRequestGone,
      },
      laoByToken.keys.toSet(),
    );
  });

  test('every token is recognised as a leave token; other text is not', () {
    for (final token in laoByToken.keys) {
      expect(
        LeaveErrorCode.tokenOf(Failure.validation(message: token)),
        token,
      );
    }
    expect(
      LeaveErrorCode.tokenOf(const Failure.validation(message: 'Leave changed')),
      isNull,
    );
    expect(
      LeaveErrorCode.tokenOf(const Failure.server(message: 'leaveChanged')),
      isNull,
    );
  });

  test('which refusals mean the screen is out of date', () {
    bool approver(String token) =>
        LeaveErrorCode.isStaleForApprover(Failure.validation(message: token));
    bool owner(String token) =>
        LeaveErrorCode.isStaleForOwner(Failure.validation(message: token));

    expect(laoByToken.keys.where(approver).toSet(), {
      'leaveStepChanged',
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveNotApprover',
      'leaveRequestGone',
    });
    expect(laoByToken.keys.where(owner).toSet(), {
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveRequestGone',
      'leaveStartedContactHr',
    });
    expect(
      LeaveErrorCode.isStaleForOwner(const Failure.network(message: 'x')),
      isFalse,
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

  group('what an approver is told (#70)', () {
    const refusal = Failure.validation(message: 'leaveInsufficientBalance');

    test('not enough days left is about the employee, with what to do next',
        () {
      final outcome = LeaveDecisionOutcome.failed(refusal);

      expect(
        LeaveCopy.decisionRefusal(en, outcome),
        'This employee does not have enough days left for this leave. '
        'HR must add days, or the request has to be rejected.',
      );
      expect(
        LeaveCopy.decisionRefusal(lo, outcome),
        'ພະນັກງານຄົນນີ້ມີວັນລາຄົງເຫຼືອບໍ່ພຽງພໍສຳລັບການລານີ້. '
        'ໃຫ້ HR ເພີ່ມວັນລາ ຫຼື ປະຕິເສດຄຳຮ້ອງນີ້.',
      );
    });

    test('the employee who asks still gets their own wording', () {
      expect(
        refusal.localize(en),
        "You don't have enough leave balance for those dates.",
      );
    });
  });
}
