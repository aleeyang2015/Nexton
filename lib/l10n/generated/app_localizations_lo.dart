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
  String get currentTimeLabel => 'ເວລາປັດຈຸບັນ';

  @override
  String get regularTimeBadge => 'REG - ເວລາປົກກະຕິ';

  @override
  String get shiftHoursPlaceholder =>
      'ກະເຊົ້າ: 08:00 - 12:00 | ກະແລງ: 13:00 - 17:00';

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
  String get slideToClockOut => 'ເລື່ອນເພື່ອລົງເວລາອອກ';

  @override
  String get clockingIn => 'ກຳລັງລົງເວລາເຂົ້າ…';

  @override
  String get clockingOut => 'ກຳລັງລົງເວລາອອກ…';

  @override
  String get clockInSuccess => 'ລົງເວລາເຂົ້າສຳເລັດ';

  @override
  String get clockOutSuccess => 'ລົງເວລາອອກສຳເລັດ';

  @override
  String clockInSuccessInSession(String session) {
    return 'ລົງເວລາເຂົ້າສຳເລັດ ($session)';
  }

  @override
  String clockOutSuccessInSession(String session) {
    return 'ລົງເວລາອອກສຳເລັດ ($session)';
  }

  @override
  String punchLateBy(int minutes) {
    return 'ທ່ານມາຊ້າ $minutes ນາທີ';
  }

  @override
  String get punchNotVerified => 'ບັນທຶກແລ້ວ ແຕ່ບໍ່ສາມາດຢືນຢັນສະຖານທີ່ໄດ້';

  @override
  String punchNotVerifiedBecause(String reason) {
    return 'ບັນທຶກແລ້ວ ແຕ່ບໍ່ສາມາດຢືນຢັນສະຖານທີ່ໄດ້: $reason';
  }

  @override
  String get punchPendingVerification =>
      'ບັນທຶກແລ້ວ. ກຳລັງລໍຖ້າການກວດສອບສະຖານທີ່';

  @override
  String get rejectionOutsideGeofence => 'ທ່ານຢູ່ນອກເຂດທີ່ກຳນົດ';

  @override
  String get rejectionMissingCoordinates => 'ບໍ່ໄດ້ສົ່ງພິກັດສະຖານທີ່';

  @override
  String get rejectionUnknownWifi => 'ບໍ່ຮູ້ຈັກເຄືອຂ່າຍ WiFi ນີ້';

  @override
  String get rejectionMissingBssid => 'ບໍ່ໄດ້ສົ່ງຂໍ້ມູນເຄືອຂ່າຍ WiFi';

  @override
  String get ruleMockLocationDetected =>
      'ກຳລັງເປີດ Fake GPS. ກະລຸນາປິດກ່ອນ ແລ້ວລອງໃໝ່.';

  @override
  String get ruleEmployeeNotFound =>
      'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ຜູກກັບຂໍ້ມູນພະນັກງານ. ກະລຸນາຕິດຕໍ່ HR.';

  @override
  String get ruleNoShiftAssigned =>
      'ຍັງບໍ່ໄດ້ກຳນົດກະການເຮັດວຽກ. ກະລຸນາຕິດຕໍ່ HR.';

  @override
  String get ruleOutsideShiftHours => 'ໝົດເວລາລົງເວລາເຂົ້າຂອງມື້ນີ້ແລ້ວ.';

  @override
  String get ruleOvernightSessionDone => 'ທ່ານໄດ້ເຮັດກະຂ້າມຄືນຈົບໄປແລ້ວ.';

  @override
  String get ruleSessionAlreadyStarted =>
      'ທ່ານລົງເວລາເຂົ້າໄປແລ້ວ. ກະລຸນາລົງເວລາອອກແທນ.';

  @override
  String get ruleSessionAlreadyCompleted =>
      'ຊ່ວງນີ້ມີທັງລົງເວລາເຂົ້າ ແລະ ອອກຄົບແລ້ວ.';

  @override
  String get ruleSessionAlreadyCheckedOut => 'ທ່ານລົງເວລາອອກຂອງຊ່ວງນີ້ໄປແລ້ວ.';

  @override
  String get ruleSessionNotStarted =>
      'ທ່ານຍັງບໍ່ໄດ້ລົງເວລາເຂົ້າຂອງຊ່ວງນີ້ເທື່ອ.';

  @override
  String get ruleAfterCheckoutWindow => 'ເລີຍເວລາລົງເວລາອອກແລ້ວ.';

  @override
  String get ruleEarlyCheckoutRequiresReason => 'ການອອກກ່ອນເວລາຕ້ອງລະບຸເຫດຜົນ.';

  @override
  String get earlyCheckoutTitle => 'ເຫດຜົນທີ່ອອກກ່ອນເວລາ';

  @override
  String get earlyCheckoutPrompt =>
      'ທ່ານກຳລັງລົງເວລາອອກກ່ອນເວລາ. ກະລຸນາລະບຸເຫດຜົນ.';

  @override
  String earlyCheckoutPromptBefore(String time) {
    return 'ການອອກກ່ອນ $time ຕ້ອງລະບຸເຫດຜົນ.';
  }

  @override
  String get earlyCheckoutHint => 'ຕົວຢ່າງ: ໄປພົບແພດ';

  @override
  String get earlyCheckoutSubmit => 'ສົ່ງ';

  @override
  String get cancel => 'ຍົກເລີກ';

  @override
  String get ok => 'ຕົກລົງ';

  @override
  String get retry => 'ລອງໃໝ່';

  @override
  String get locationUnavailable =>
      'ບໍ່ສາມາດອ່ານສະຖານທີ່ໄດ້. ກະລຸນາເປີດ GPS ແລະ ອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ ແລ້ວລອງໃໝ່.';

  @override
  String get locationServiceDisabled =>
      'ບໍລິການສະຖານທີ່ຖືກປິດຢູ່. ກະລຸນາເປີດກ່ອນ ແລ້ວລອງໃໝ່.';

  @override
  String get locationPermissionDenied =>
      'Next On ຕ້ອງການສະຖານທີ່ຂອງທ່ານເພື່ອລົງເວລາ. ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ ແລ້ວລອງໃໝ່.';

  @override
  String get locationPermissionDeniedForever =>
      'ການເຂົ້າເຖິງສະຖານທີ່ຖືກບລັອກ. ກະລຸນາເປີດ ຕັ້ງຄ່າ ແລ້ວອະນຸຍາດສະຖານທີ່ໃຫ້ Next On ແລ້ວລອງໃໝ່.';

  @override
  String get locationTimeout =>
      'ບໍ່ສາມາດຫາສັນຍານສະຖານທີ່ໄດ້. ກະລຸນາຍ້າຍໄປບ່ອນທີ່ເຫັນທ້ອງຟ້າຊັດເຈນ ແລ້ວລອງໃໝ່.';

  @override
  String get wifiUnavailable =>
      'ບໍ່ສາມາດອ່ານເຄືອຂ່າຍ WiFi ໄດ້. ກະລຸນາເຊື່ອມຕໍ່ WiFi ຂອງຫ້ອງການ ແລ້ວລອງໃໝ່.';

  @override
  String get fieldReasonRequired => 'ກະລຸນາລະບຸເຫດຜົນຂອງວຽກນອກສະຖານທີ່.';

  @override
  String get mockLocationDetected =>
      'ກຳລັງເປີດ Fake GPS. ກະລຸນາປິດກ່ອນ ແລ້ວລອງໃໝ່.';

  @override
  String get clockCooldownActive =>
      'ລົງເວລາຖີ່ເກີນໄປ. ກະລຸນາລໍຖ້າສັກຄູ່ກ່ອນລອງໃໝ່.';

  @override
  String get attendanceLoadFailed =>
      'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການລົງເວລາຂອງມື້ນີ້ໄດ້.';

  @override
  String get noTimeYet => '--:--';

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
  String get attendanceHistoryTitle => 'ປະຫວັດການເຂົ້າວຽກ';

  @override
  String get viewAll => 'ເບິ່ງທັງໝົດ';

  @override
  String get daysPresent => 'ມື້ມາວຽກ';

  @override
  String get daysLate => 'ມາວຽກຊ້າ';

  @override
  String get daysAbsent => 'ຂາດວຽກ';

  @override
  String get attendanceHistoryEmpty => 'ບໍ່ມີບັນທຶກໃນເດືອນນີ້';

  @override
  String get attendancePresentStatus => 'ມາເຮັດວຽກ';

  @override
  String get attendanceLateStatus => 'ມາຊ້າ';

  @override
  String attendanceLateByMinutes(int minutes) {
    return 'ມາຊ້າ $minutes ນາທີ';
  }

  @override
  String get attendanceEarlyExitStatus => 'ອອກກ່ອນເວລາ';

  @override
  String attendanceEarlyExitByMinutes(int minutes) {
    return 'ອອກກ່ອນ $minutes ນາທີ';
  }

  @override
  String attendanceOvertimeHours(String hours) {
    return 'ໂອທີ $hours ຊົ່ວໂມງ';
  }

  @override
  String get hoursUnit => 'ຊົ່ວໂມງ';

  @override
  String get shiftMorningLabel => 'ກະເຊົ້າ';

  @override
  String get shiftAfternoonLabel => 'ກະແລງ';

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
