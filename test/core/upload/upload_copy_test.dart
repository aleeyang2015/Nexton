import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/upload/data/upload_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// Each refused upload in plain Lao (and English).
void main() {
  final lo = AppLocalizationsLo();
  final en = AppLocalizationsEn();

  String say(String token, {bool lao = true}) =>
      Failure.validation(message: token).localize(lao ? lo : en);

  test('Lao', () {
    expect(say(UploadErrorCode.tokenFileTooLarge), 'ໄຟລ໌ໃຫຍ່ເກີນ 5 MB');
    expect(
      say(UploadErrorCode.tokenInvalidFile),
      'ອ່ານໄຟລ໌ບໍ່ໄດ້, ກະລຸນາເລືອກໃໝ່',
    );
    expect(
      say(UploadErrorCode.tokenStorageUnavailable),
      'ຕອນນີ້ອັບໂຫຼດໄຟລ໌ບໍ່ໄດ້, ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ',
    );
    expect(
      say(UploadErrorCode.tokenPermissionDenied),
      'ກະລຸນາອະນຸຍາດໃຫ້ແອັບໃຊ້ກ້ອງ ຫຼື ຮູບພາບ ໃນການຕັ້ງຄ່າໂທລະສັບ',
    );
  });

  test('English', () {
    expect(
      say(UploadErrorCode.tokenFileTooLarge, lao: false),
      'The file is over 5 MB',
    );
    expect(
      say(UploadErrorCode.tokenStorageUnavailable, lao: false),
      'File upload is not available; contact HR',
    );
  });
}
