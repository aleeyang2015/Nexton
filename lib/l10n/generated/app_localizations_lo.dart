// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lao (`lo`).
class AppLocalizationsLo extends AppLocalizations {
  AppLocalizationsLo([String locale = 'lo']) : super(locale);

  @override
  String get appTitle => 'Next On';

  @override
  String get login => 'ເຂົ້າສູ່ລະບົບ';

  @override
  String get email => 'ອີເມວ';

  @override
  String get emailHint => 'Example@gmail.com';

  @override
  String get password => 'ລະຫັດຜ່ານ';

  @override
  String get passwordHint => 'ປ້ອນລະຫັດຜ່ານ';

  @override
  String get forgotPassword => 'ລືມລະຫັດຜ່ານ ?';

  @override
  String get rememberMe => 'ຈື່ອີເມວຂ້ອຍໄວ້';

  @override
  String get genericError => 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';

  @override
  String get changePassword => 'ປ່ຽນລະຫັດຜ່ານ';

  @override
  String get changePasswordForcedNotice =>
      'ກະລຸນາຕັ້ງລະຫັດຜ່ານໃໝ່ກ່ອນເຂົ້ານຳໃຊ້ລະບົບ';

  @override
  String get changePasswordVoluntaryNotice =>
      'ຕັ້ງລະຫັດຜ່ານໃໝ່ສຳລັບບັນຊີຂອງທ່ານ';

  @override
  String get currentPassword => 'ລະຫັດຜ່ານປັດຈຸບັນ';

  @override
  String get currentPasswordHint => 'ປ້ອນລະຫັດຜ່ານປັດຈຸບັນ';

  @override
  String get newPassword => 'ລະຫັດຜ່ານໃໝ່';

  @override
  String get newPasswordHint => 'ຢ່າງໜ້ອຍ 8 ຕົວອັກສອນ';

  @override
  String get confirmNewPassword => 'ຢືນຢັນລະຫັດຜ່ານໃໝ່';

  @override
  String get confirmNewPasswordHint => 'ປ້ອນລະຫັດຜ່ານໃໝ່ອີກຄັ້ງ';

  @override
  String get savePassword => 'ບັນທຶກລະຫັດຜ່ານ';

  @override
  String get logout => 'ອອກຈາກລະບົບ';

  @override
  String get changePasswordSuccess => 'ປ່ຽນລະຫັດຜ່ານສຳເລັດ';

  @override
  String get clockInOut => 'ເຂົ້າ/ອອກວຽກ';

  @override
  String get activities => 'ການເຄື່ອນໄຫວ';

  @override
  String get documents => 'ເອກະສານ';

  @override
  String get reports => 'ລາຍງານ';

  @override
  String get departments => 'ພາກສ່ວນ';

  @override
  String get settings => 'ຕັ້ງຄ່າ';

  @override
  String get notifications => 'ແຈ້ງເຕືອນ';

  @override
  String get profile => 'ໂປຣໄຟລ໌';

  @override
  String get notCheckedIn => 'ຍັງບໍ່ໄດ້ລົງເວລາເຂົ້າ';

  @override
  String get checkedInStatus => 'ລົງເວລາເຂົ້າແລ້ວ';

  @override
  String clockInOpensAt(String time) {
    return 'ລົງເວລາເຂົ້າໄດ້ເວລາ $time';
  }

  @override
  String get timeIn => 'ເວລາເຂົ້າ';

  @override
  String get timeOut => 'ເວລາອອກ';

  @override
  String get slideToClockIn => 'ເລື່ອນເພື່ອລົງເວລາເຂົ້າ';

  @override
  String clockMethodsLabel(String methods) {
    return 'ວິທີລົງເວລາ: $methods';
  }

  @override
  String get methodGps => 'GPS';

  @override
  String get methodWifi => 'WiFi';

  @override
  String get methodBiometric => 'ລາຍນິ້ວມື';

  @override
  String get methodField => 'ວຽກນອກ';

  @override
  String get navList => 'ລາຍການ';

  @override
  String get navHome => 'ໜ້າຫຼັກ';

  @override
  String get navProfile => 'ໂປຣຟາຍ';

  @override
  String get comingSoon => 'ກຳລັງພັດທະນາ';

  @override
  String get workHours => 'ຊົ່ວໂມງເຮັດວຽກ';

  @override
  String get leaveDays => 'ວັນລາພັກ';

  @override
  String get tasksDone => 'ວຽກສຳເລັດ';

  @override
  String get personal => 'ຂໍ້ມູນສ່ວນຕົວ';

  @override
  String get help => 'ຊ່ວຍເຫຼືອ';

  @override
  String get language => 'ພາສາ';

  @override
  String get lao => 'ລາວ';

  @override
  String get english => 'English';

  @override
  String get emailRequired => 'ກະລຸນາປ້ອນອີເມວ';

  @override
  String get emailInvalid => 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ';

  @override
  String get passwordRequired => 'ກະລຸນາປ້ອນລະຫັດຜ່ານ';

  @override
  String passwordTooShort(int min) {
    return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ $min ຕົວອັກສອນ';
  }

  @override
  String get currentPasswordRequired => 'ກະລຸນາປ້ອນລະຫັດຜ່ານປັດຈຸບັນ';

  @override
  String get newPasswordSameAsCurrent =>
      'ລະຫັດຜ່ານໃໝ່ຕ້ອງບໍ່ຊ້ຳກັບລະຫັດຜ່ານເກົ່າ';

  @override
  String get confirmPasswordMismatch => 'ລະຫັດຜ່ານຢືນຢັນບໍ່ຕົງກັນ';

  @override
  String get networkError => 'ເກີດຂໍ້ຜິດພາດເຄືອຂ່າຍ. ກະລຸນາລອງໃໝ່.';

  @override
  String get serverError => 'ມີບັນຫາຈາກລະບົບ. ກະລຸນາລອງໃໝ່ພາຍຫຼັງ.';

  @override
  String get requestTimeout => 'ໝົດເວລາການເຊື່ອມຕໍ່. ກະລຸນາລອງໃໝ່.';

  @override
  String get requestCancelled => 'ການຮ້ອງຂໍຖືກຍົກເລີກ.';

  @override
  String get noInternetConnection => 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ.';

  @override
  String get invalidCredentials => 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ.';

  @override
  String get userInactive =>
      'ບັນຊີຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ຜູ້ດູແລລະບົບ.';

  @override
  String get tooManyAttempts => 'ພະຍາຍາມຫຼາຍເກີນໄປ. ກະລຸນາລອງໃໝ່ພາຍຫຼັງ.';

  @override
  String get currentPasswordIncorrect => 'ລະຫັດຜ່ານປັດຈຸບັນບໍ່ຖືກຕ້ອງ.';

  @override
  String get resourceNotFound => 'ບໍ່ພົບຂໍ້ມູນທີ່ຮ້ອງຂໍ.';

  @override
  String get sessionExpired => 'ເຊສຊັນຂອງທ່ານໝົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.';

  @override
  String get unauthorized => 'ບໍ່ໄດ້ຮັບອະນຸຍາດ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.';

  @override
  String get accessForbidden => 'ບໍ່ໄດ້ຮັບອະນຸຍາດເຂົ້າເຖິງ.';

  @override
  String get badRequest => 'ຄຳຮ້ອງຂໍບໍ່ຖືກຕ້ອງ. ກະລຸນາກວດສອບຂໍ້ມູນ.';

  @override
  String get pageNotFoundTitle => 'ບໍ່ພົບໜ້ານີ້';

  @override
  String get pageNotFoundHeading => '404 - ບໍ່ພົບໜ້ານີ້';

  @override
  String get pageNotFoundMessage => 'ບໍ່ພົບໜ້າທີ່ທ່ານກຳລັງຊອກຫາ.';

  @override
  String get goHome => 'ກັບຄືນໜ້າຫຼັກ';

  @override
  String errorDetailsLabel(String details) {
    return 'ຂໍ້ຜິດພາດ: $details';
  }
}
