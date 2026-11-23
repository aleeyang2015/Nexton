// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lao (`lo`).
class AppLocalizationsLo extends AppLocalizations {
  AppLocalizationsLo([String locale = 'lo']) : super(locale);

  @override
  String get appTitle => 'NEXTON';

  @override
  String get login => 'ເຂົ້າສູ່ລະບົບ';

  @override
  String get loginSubtitle => 'ຍິນດີຕ້ອນຮັບສູ່ລະບົບບໍລິຫານ NEXTON';

  @override
  String get email => 'ອີເມວ';

  @override
  String get emailHint => 'example@gmail.com';

  @override
  String get password => 'ລະຫັດຜ່ານ';

  @override
  String get passwordHint => 'ປ້ອນລະຫັດຜ່ານ';

  @override
  String get forgotPassword => 'ລືມລະຫັດຜ່ານ ?';

  @override
  String get rememberMe => 'ຈື່ອີເມວຂ້ອຍໄວ້';

  @override
  String get loginOrLoginWith => 'ຫຼື ເຂົ້າສູ່ລະບົບດ້ວຍ';

  @override
  String loginFooter(Object version) {
    return 'NEXTON v$version • ລະບົບບໍລິຫານບຸກຄະລາກອນ';
  }

  @override
  String get genericError => 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';

  @override
  String get changePassword => 'ປ່ຽນລະຫັດຜ່ານ';

  @override
  String get changePasswordSecurityTitle => 'ຮັກສາບັນຊີຂອງທ່ານໃຫ້ປອດໄພ';

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
  String get attendanceHistoryMenu => 'ປະຫວັດເຂົ້າອອກວຽກ';

  @override
  String get leaveMenu => 'ລາພັກ';

  @override
  String get leaveHistoryMenu => 'ປະຫວັດລາພັກ';

  @override
  String get delegateTaskMenu => 'ມອບວຽກ';

  @override
  String get delegateTaskHistoryMenu => 'ປະຫວັດມອບວຽກ';

  @override
  String get salaryHistoryMenu => 'ປະຫວັດເງິນເດືອນ';

  @override
  String get forgotClockInMenu => 'ລືມລົງເວລາ';

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
  String get profile => 'ໂປຣຟາຍ';

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
  String get slideToClockIn => 'ເລື່ອນເພື່ອລົງເວລາເຂົ້າ';

  @override
  String get clockMethodsLabel => 'ວິທີລົງເວລາ:';

  @override
  String get sessionClockInLabel => 'ເຂົ້າ';

  @override
  String get sessionClockOutLabel => 'ອອກ';

  @override
  String get sessionAwaitingClockOut => '(ລໍຖ້າ)';

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
      'NEXTON ຕ້ອງການສະຖານທີ່ຂອງທ່ານເພື່ອລົງເວລາ. ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງສະຖານທີ່ ແລ້ວລອງໃໝ່.';

  @override
  String get locationPermissionDeniedForever =>
      'ການເຂົ້າເຖິງສະຖານທີ່ຖືກບລັອກ. ກະລຸນາເປີດ ຕັ້ງຄ່າ ແລ້ວອະນຸຍາດສະຖານທີ່ໃຫ້ NEXTON ແລ້ວລອງໃໝ່.';

  @override
  String get locationTimeout =>
      'ບໍ່ສາມາດຫາສັນຍານສະຖານທີ່ໄດ້. ກະລຸນາຍ້າຍໄປບ່ອນທີ່ເຫັນທ້ອງຟ້າຊັດເຈນ ແລ້ວລອງໃໝ່.';

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
  String get homeServicesTitle => 'ລາຍການ & ບໍລິການ (Services)';

  @override
  String menuItemCount(int count) {
    return '$count ລາຍການ';
  }

  @override
  String get navHome => 'ໜ້າຫຼັກ';

  @override
  String get navProfile => 'ໂປຣຟາຍ';

  @override
  String get comingSoon => 'ກຳລັງພັດທະນາ';

  @override
  String get workHours => 'ຊົ່ວໂມງວຽກ';

  @override
  String get lateArrivals => 'ມາຊ້າ';

  @override
  String get absences => 'ຂາດວຽກ';

  @override
  String get personal => 'ຂໍ້ມູນສ່ວນຕົວ';

  @override
  String get help => 'ຊ່ວຍເຫຼືອ';

  @override
  String get profileStatusActive => 'ປະຈຸບັນ (Active)';

  @override
  String get attendanceHistoryTitle => 'ປະຫວັດການເຂົ້າວຽກ';

  @override
  String get homeMonthStatsTitle => 'ສະຖິຕິການເຮັດວຽກເດືອນນີ້';

  @override
  String get viewDetails => 'ເບິ່ງລາຍລະອຽດ';

  @override
  String get daysPresent => 'ມາວຽກ';

  @override
  String get daysLate => 'ມາຊ້າ';

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
  String get hoursUnit => 'ຊົ່ວໂມງ';

  @override
  String get shiftMorningLabel => 'ກະເຊົ້າ';

  @override
  String get shiftAfternoonLabel => 'ກະແລງ';

  @override
  String get salaryHistoryTitle => 'ເງິນເດືອນ';

  @override
  String get salaryFilterAll => 'ທັງໝົດ';

  @override
  String get salaryFilterPaid => 'ຈ່າຍແລ້ວ';

  @override
  String get salaryNetSalaryLabel => 'ເງິນເດືອນສຸດທິ';

  @override
  String get salaryPaidOnLabel => 'ຈ່າຍວັນທີ';

  @override
  String get salaryIncomeSection => 'ລາຍຮັບ';

  @override
  String get salaryDeductionsSection => 'ລາຍການຫັກ';

  @override
  String get salaryBaseSalary => 'ເງິນເດືອນພື້ນຖານ';

  @override
  String get salarySocialSecurity => 'ປະກັນສັງຄົມ';

  @override
  String get salaryIncomeTax => 'ອາກອນເງິນເດືອນ';

  @override
  String get salaryWorkingDaysLabel => 'ມື້ເຮັດວຽກ';

  @override
  String get salaryOvertimeLabel => 'ຊົ່ວໂມງໂອທີ';

  @override
  String get salaryUnpaidLeaveLabel => 'ລາພັກບໍ່ໄດ້ຮັບເງິນ (ວັນ)';

  @override
  String get salaryDownloadPdf => 'ເບິ່ງໃບເງິນເດືອນ (PDF)';

  @override
  String get payslipDetailTitle => 'ໃບເງິນເດືອນ';

  @override
  String get salaryGrossLabel => 'ລາຍຮັບລວມ';

  @override
  String get salaryTotalDeductionsLabel => 'ຫັກລວມ';

  @override
  String get salaryTaxableIncomeLabel => 'ລາຍໄດ້ຄິດອາກອນ';

  @override
  String get salaryUnitTimes => 'ຄັ້ງ';

  @override
  String get salaryUnitDays => 'ມື້';

  @override
  String get salaryHistoryEmpty => 'ບໍ່ມີຂໍ້ມູນເງິນເດືອນ';

  @override
  String get salaryHistoryLoadFailed => 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນເງິນເດືອນໄດ້.';

  @override
  String get payslipDetailLoadFailed => 'ບໍ່ສາມາດໂຫຼດໃບເງິນເດືອນໄດ້.';

  @override
  String get salaryPdfInvalid => 'ບໍ່ສາມາດອ່ານໄຟລ໌ PDF ໃບເງິນເດືອນໄດ້.';

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

  @override
  String get timeOffHistoryTab => 'ປະຫວັດການລາພັກ';

  @override
  String get timeOffRequestTab => 'ຂໍລາພັກ';

  @override
  String get leaveFilterAll => 'ທັງໝົດ';

  @override
  String get leaveCategorySick => 'ລາປ່ວຍ';

  @override
  String get leaveCategoryPersonal => 'ລາກິດ';

  @override
  String get leaveCategoryAnnual => 'ລາພັກປະຈຳປີ';

  @override
  String get leaveCategoryRest => 'ລາພັກຜ່ອນ';

  @override
  String get leaveDateFrom => 'ຈາກວັນທີ';

  @override
  String get leaveDateTo => 'ຫາວັນທີ';

  @override
  String get daysCountUnit => 'ວັນ';

  @override
  String get leaveStatusPending => 'ກຳລັງດຳເນີນການ';

  @override
  String get leaveStatusApproved => 'ອະນຸມັດແລ້ວ';

  @override
  String get leaveStatusRejected => 'ບໍ່ອະນຸມັດ';

  @override
  String get leaveStepSubmitted => 'ສົ່ງຄຳຂໍ';

  @override
  String get leaveStepManagerReview => 'ຫົວໜ້າພິຈາລະນາ';

  @override
  String get leaveStepManagerWaiting => 'ລໍຖ້າຫົວໜ້າພິຈາລະນາ';

  @override
  String get leaveStepHrApproval => 'HR ອະນຸມັດ';

  @override
  String get leaveReviewerCommentLabel => 'ຄວາມຄິດເຫັນ';

  @override
  String get leaveHistoryLoadFailed => 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການລາພັກໄດ້.';

  @override
  String get leaveHistoryEmpty => 'ບໍ່ມີຂໍ້ມູນການລາພັກ';

  @override
  String leaveDaysSuffix(String days) {
    return '$days ວັນ';
  }

  @override
  String leaveTotalDaysSuffix(int days) {
    return 'ທັງໝົດ $days ວັນ';
  }

  @override
  String get leaveRequestCategoryLabel => 'ປະເພດການລາ';

  @override
  String get leaveRequestReasonLabel => 'ເຫດຜົນ';

  @override
  String get leaveRequestReasonHint => 'ອະທິບາຍເຫດຜົນການລາ';

  @override
  String get leaveRequestSubmit => 'ສົ່ງຄຳຂໍ';

  @override
  String get leaveRequestSubmitSuccess => 'ສົ່ງຄຳຂໍລາພັກສຳເລັດ';

  @override
  String get selectDate => 'ເລືອກວັນທີ';

  @override
  String get leaveBalanceRemainingLabel => 'ວັນລາພັກຍັງເຫຼືອ';

  @override
  String leaveBalanceUsedLabel(String days) {
    return 'ໃຊ້ໄປແລ້ວ $days ວັນ';
  }

  @override
  String leaveYearLabel(int year) {
    return 'ປີ $year';
  }

  @override
  String get leaveSelectDatesLabel => 'ເລືອກວັນທີ່ລາພັກ';

  @override
  String get leaveDatesTotalPrefix => 'ລວມທັງໝົດ:';

  @override
  String get leaveNoDatesSelected => 'ຍັງບໍ່ໄດ້ເລືອກວັນທີ';

  @override
  String get leaveReturnToWorkLabel => 'ວັນທີ່ກັບມາເລີ່ມວຽກ';

  @override
  String get leaveSelectButtonLabel => 'ເລືອກ';

  @override
  String get leaveAttachFileLabel => 'ແນບໄຟລ໌';

  @override
  String get leaveOptionalBadge => 'ທາງເລືອກ';

  @override
  String get leaveChooseFileButton => 'ເລືອກໄຟລ໌';

  @override
  String get leaveAttachNoFiles => 'ຍັງບໍ່ໄດ້ແນບໄຟລ໌';

  @override
  String get leaveAttachUploading => 'ກຳລັງອັບໂຫລດ…';

  @override
  String get leaveAttachUploaded => 'ອັບໂຫລດໄຟລ໌ແລ້ວ';

  @override
  String get leaveAttachUploadFailed => 'ອັບໂຫລດໄຟລ໌ບໍ່ສຳເລັດ. ກະລຸນາລອງໃໝ່.';

  @override
  String get leaveFileRemove => 'ລຶບໄຟລ໌';

  @override
  String get leaveFileOpenFailed => 'ເປີດໄຟລ໌ນີ້ບໍ່ໄດ້';

  @override
  String get fileLinkExpired =>
      'ລິ້ງນີ້ໝົດອາຍຸແລ້ວ. ກະລຸນາປິດ ແລ້ວເປີດອີກຄັ້ງ.';

  @override
  String get fileLinkExpiredRefresh =>
      'ລິ້ງນີ້ໝົດອາຍຸແລ້ວ. ກະລຸນາດຶງລາຍການລົງເພື່ອໂຫຼດໃໝ່.';

  @override
  String get timeOffApprovalsTab => 'ອະນຸມັດຂໍລາພັກ';

  @override
  String leaveApprovalsPendingHeader(String count) {
    return 'ລາຍການທີ່ຕ້ອງອະນຸມັດ ($count)';
  }

  @override
  String get leaveApprovalsHistoryHeader => 'ປະຫວັດການອະນຸມັດ';

  @override
  String get leaveApprovalNewBadge => 'ໃໝ່';

  @override
  String get leaveApprovalApproveAction => 'ອະນຸມັດ';

  @override
  String get leaveApprovalFinalAction => 'ອະນຸມັດຂັ້ນສຸດທ້າຍ';

  @override
  String get leaveApprovalClearedNotice => 'ຫົວໜ້າພະແນກອະນຸມັດແລ້ວ';

  @override
  String get leaveApprovalRejectAction => 'ປະຕິເສດ';

  @override
  String get leaveApprovalsLoadFailed => 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນອະນຸມັດໄດ້.';

  @override
  String get leaveApprovalsPendingEmpty => 'ບໍ່ມີລາຍການທີ່ຕ້ອງອະນຸມັດ';

  @override
  String get leaveApprovalsHistoryEmpty => 'ບໍ່ມີປະຫວັດການອະນຸມັດ';

  @override
  String get leaveApprovalDecideFailed => 'ດຳເນີນການບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';

  @override
  String get leaveTypeLoadFailed => 'ບໍ່ສາມາດໂຫຼດປະເພດການລາໄດ້.';

  @override
  String get leaveStatusCancelled => 'ຍົກເລີກແລ້ວ';

  @override
  String get leaveStepDeptHead => 'ຫົວໜ້າ';

  @override
  String get leaveStepHr => 'ຝ່າຍບຸກຄະລາກອນ';

  @override
  String get leaveDurationLabel => 'ຊ່ວງເວລາ';

  @override
  String get leaveDurationFullDay => 'ເຕັມມື້';

  @override
  String get leaveDurationFirstHalf => 'ຕອນເຊົ້າ';

  @override
  String get leaveDurationSecondHalf => 'ຕອນບ່າຍ';

  @override
  String get leaveHalfDayLabel => 'ເຄິ່ງມື້ (0.5)';

  @override
  String get leaveRequiredBadge => 'ຈຳເປັນ';

  @override
  String get leaveRequiresAttachmentBlocked =>
      'ປະເພດນີ້ຕ້ອງແນບໄຟລ໌ ກະລຸນາແນບໄຟລ໌ກ່ອນສົ່ງ';

  @override
  String get leaveInsufficientBalanceHint =>
      'ວັນລາຄົງເຫຼືອບໍ່ພຽງພໍສຳລັບວັນທີ່ເລືອກ.';

  @override
  String get leaveReturnDateHint =>
      'ວັນທີ່ກັບມາເລີ່ມວຽກຕ້ອງຢູ່ຫຼັງວັນລາພັກສຸດທ້າຍ.';

  @override
  String leaveMaxDaysHint(String days) {
    return 'ການລາປະເພດນີ້ຂໍໄດ້ສູງສຸດ $days ວັນຕໍ່ຄັ້ງ.';
  }

  @override
  String get leaveEditAction => 'ແກ້ໄຂຄຳຮ້ອງ';

  @override
  String get leaveCancelAction => 'ຍົກເລີກຄຳຮ້ອງ';

  @override
  String get leaveCancelConfirm =>
      'ຍົກເລີກຄຳຮ້ອງລານີ້ບໍ? ວັນທີ່ຈອງໄວ້ຈະຖືກຄືນສູ່ຍອດຄົງເຫຼືອ.';

  @override
  String get leaveRequestUpdated => 'ອັບເດດຄຳຮ້ອງລາແລ້ວ';

  @override
  String get leaveRequestCancelled => 'ຍົກເລີກຄຳຮ້ອງລາແລ້ວ';

  @override
  String get leaveRequestCancelFailed => 'ບໍ່ສາມາດຍົກເລີກຄຳຮ້ອງໄດ້.';

  @override
  String get leaveRejectReasonTitle => 'ເຫດຜົນການປະຕິເສດ';

  @override
  String get leaveRejectReasonHint => 'ແຈ້ງໃຫ້ພະນັກງານຮູ້ເຫດຜົນ';

  @override
  String get leaveRejectReasonSubmit => 'ປະຕິເສດ';

  @override
  String get leaveStepRefreshed =>
      'ມີຄົນອື່ນຫາກໍ່ດຳເນີນການກັບຄຳຮ້ອງນີ້ — ກະລຸນາກວດຄືນ.';

  @override
  String get leaveDetailTitle => 'ລາຍລະອຽດການລາ';

  @override
  String get leaveApprovalChainLabel => 'ຄວາມຄືບໜ້າການອະນຸມັດ';

  @override
  String get leaveApproverNoteLabel => 'ໝາຍເຫດ';

  @override
  String get leaveAttachmentsLabel => 'ໄຟລ໌ແນບ';

  @override
  String get leavePendingRequestExists =>
      'ທ່ານມີຄຳຮ້ອງລາທີ່ລໍຖ້າອະນຸມັດຢູ່ແລ້ວ ກະລຸນາລໍຖ້າໃຫ້ແລ້ວກ່ອນ.';

  @override
  String get leaveOverlapping => 'ວັນທີ່ເລືອກຊ້ອນກັບຄຳຮ້ອງລາອື່ນ.';

  @override
  String get leaveInsufficientBalance =>
      'ວັນລາຄົງເຫຼືອບໍ່ພຽງພໍສຳລັບວັນທີ່ເລືອກ.';

  @override
  String get leaveStepChanged => 'ຄຳຮ້ອງນີ້ຫາກໍ່ຖືກອັບເດດ — ກະລຸນາກວດຄືນ.';

  @override
  String get leaveNotApprover => 'ທ່ານບໍ່ມີສິດອະນຸມັດຂັ້ນຕອນນີ້.';

  @override
  String get leaveInvalidStatus => 'ຄຳຮ້ອງນີ້ບໍ່ສາມາດປ່ຽນແປງໄດ້ອີກຕໍ່ໄປ.';

  @override
  String get leaveEmployeeNotFound =>
      'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ເຊື່ອມກັບຂໍ້ມູນພະນັກງານ.';

  @override
  String get leaveTypePickerTitle => 'ເລືອກປະເພດການລາ';

  @override
  String get leaveTypeSearchHint => 'ຄົ້ນຫາ';

  @override
  String get leaveTypeSearchEmpty => 'ບໍ່ພົບປະເພດການລາທີ່ກົງກັນ';

  @override
  String get timeCorrectionTitle => 'ແກ້ໄຂເວລາເຂົ້າ ອອກວຽກ';

  @override
  String get timeCorrectionNoticeTitle => 'ແຈ້ງເຕືອນລະບົບ';

  @override
  String get timeCorrectionNoticeBody =>
      'ຄຳຮ້ອງຂອງທ່ານຈະຖືກສົ່ງໄປຍັງຫົວໜ້າງານ (Manager) ເພື່ອພິຈາລະນາອະນຸມັດ';

  @override
  String get timeCorrectionDateLabel => 'ວັນທີຕ້ອງການແກ້ໄຂ';

  @override
  String get timeCorrectionTypeLabel => 'ປະເພດການແກ້ໄຂ';

  @override
  String get timeCorrectionTypeForgotIn => 'ລືມລົງເວລາເຂົ້າ';

  @override
  String get timeCorrectionTypeForgotOut => 'ລືມລົງເວລາອອກ';

  @override
  String get timeCorrectionTypeBoth => 'ທັງສອງ (ເຂົ້າ & ອອກ)';

  @override
  String get timeCorrectionTypeWrongTime => 'ເວລາບໍ່ຖືກຕ້ອງ';

  @override
  String get timeCorrectionShiftLabel => 'ກະການເຮັດວຽກທີ່ກ່ຽວຂ້ອງ';

  @override
  String get timeCorrectionClockInLabel => 'ເວລາເຂົ້າຂໍແກ້';

  @override
  String get timeCorrectionClockOutLabel => 'ເວລາອອກຂໍແກ້';

  @override
  String get timeCorrectionMorning => 'ຕອນເຊົ້າ';

  @override
  String get timeCorrectionAfternoon => 'ຕອນບ່າຍ';

  @override
  String get timeCorrectionEvening => 'ຕອນແລງ';

  @override
  String get timeCorrectionInvalidTimes => 'ເວລາອອກຕ້ອງຫຼັງເວລາເຂົ້າ';

  @override
  String get timeCorrectionReasonLabel => 'ເຫດຜົນ / ລາຍລະອຽດ';

  @override
  String get timeCorrectionReasonHint => 'ລະບຸເຫດຜົນ';

  @override
  String get timeCorrectionAttachmentLabel => 'ໄຟລ໌ ຫຼື ຮູບພາບປະກອບ';

  @override
  String get timeCorrectionUploadTitle => 'ກົດເພື່ອອັບໂຫຼດ ຫຼື ຖ່າຍຮູບຫຼັກຖານ';

  @override
  String get timeCorrectionUploadHint =>
      'ຮອງຮັບຮູບຖ່າຍໃບຄຳຮ້ອງ, ຫຼັກຖານ JPG, PNG, PDF\n(ສູງສຸດ 5MB)';

  @override
  String get timeCorrectionTakePhoto => 'ຖ່າຍຮູບ';

  @override
  String get timeCorrectionChooseFile => 'ເລືອກໄຟລ໌';

  @override
  String get timeCorrectionFileTooLarge => 'ໄຟລ໌ໃຫຍ່ເກີນ 5MB';

  @override
  String get timeCorrectionSubmit => 'ສົ່ງຄຳຮ້ອງແກ້ໄຂ';

  @override
  String get timeCorrectionNoShift => 'ທ່ານຍັງບໍ່ມີກະການເຮັດວຽກ';

  @override
  String get timeCorrectionPickSegment => 'ເລືອກຊ່ວງກະ';

  @override
  String get timeCorrectionDateInFuture => 'ວັນທີຕ້ອງບໍ່ເກີນມື້ນີ້';

  @override
  String timeCorrectionDateTooOld(int days) {
    return 'ແກ້ໄຂໄດ້ສະເພາະ $days ມື້ຜ່ານມາ';
  }

  @override
  String get timeCorrectionShiftRequired =>
      'ທ່ານຍັງບໍ່ມີກະການເຮັດວຽກ, ບໍ່ສາມາດສົ່ງຄຳຮ້ອງແກ້ໄຂໄດ້';

  @override
  String get timeCorrectionTimeRequired => 'ກະລຸນາເລືອກເວລາ';

  @override
  String get timeCorrectionReasonRequired => 'ກະລຸນາລະບຸເຫດຜົນ';

  @override
  String timeCorrectionReasonTooLong(int max) {
    return 'ເຫດຜົນຍາວໄດ້ບໍ່ເກີນ $max ຕົວອັກສອນ';
  }

  @override
  String get timeCorrectionSubmitSuccess => 'ສົ່ງຄຳຮ້ອງແກ້ໄຂສຳເລັດ';

  @override
  String get cameraUnavailable => 'ບໍ່ພົບກ້ອງຖ່າຍຮູບໃນອຸປະກອນນີ້';

  @override
  String get cameraPermissionDenied =>
      'ກະລຸນາອະນຸຍາດໃຫ້ເຂົ້າເຖິງກ້ອງໃນການຕັ້ງຄ່າ ເພື່ອຖ່າຍຮູບ';

  @override
  String get cameraCaptureFailed => 'ຖ່າຍຮູບບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';

  @override
  String get cameraRetake => 'ຖ່າຍໃໝ່';

  @override
  String get cameraUsePhoto => 'ໃຊ້ຮູບນີ້';

  @override
  String get timeCorrectionHistoryMenu => 'ປະຫວັດແກ້ໄຂເວລາ';

  @override
  String get timeCorrectionHistoryTitle => 'ປະຫວັດການຮ້ອງຂໍແກ້ໄຂເວລາ';

  @override
  String get timeCorrectionSummaryTotal => 'ທັງໝົດ';

  @override
  String get timeCorrectionSummaryTotalUnit => 'ລາຍການ';

  @override
  String get timeCorrectionSummaryPending => 'ລໍຖ້າກວດ';

  @override
  String get timeCorrectionSummaryPendingUnit => 'ລໍຖ້າ';

  @override
  String get timeCorrectionSummaryApproved => 'ອະນຸມັດ';

  @override
  String get timeCorrectionSummaryApprovedUnit => 'ສຳເລັດ';

  @override
  String timeCorrectionFilterAll(int count) {
    return 'ທັງໝົດ ($count)';
  }

  @override
  String timeCorrectionFilterPending(int count) {
    return 'ລໍຖ້າ ($count)';
  }

  @override
  String timeCorrectionFilterApproved(int count) {
    return 'ອະນຸມັດ ($count)';
  }

  @override
  String timeCorrectionFilterRejected(int count) {
    return 'ປະຕິເສດ ($count)';
  }

  @override
  String get timeCorrectionStatusPending => 'ລໍຖ້າອະນຸມັດ';

  @override
  String get timeCorrectionStatusApproved => 'ອະນຸມັດແລ້ວ';

  @override
  String get timeCorrectionStatusRejected => 'ຖືກປະຕິເສດ';

  @override
  String timeCorrectionClockInAt(String time) {
    return 'ເຂົ້າ $time';
  }

  @override
  String timeCorrectionClockOutAt(String time) {
    return 'ອອກ $time';
  }

  @override
  String get timeCorrectionHistoryEmpty => 'ບໍ່ມີຄຳຮ້ອງ';

  @override
  String get timeCorrectionNewRequestTitle => 'ສ້າງຄຳຮ້ອງໃໝ່';

  @override
  String get timeCorrectionNewRequestSubtitle => 'ຮ້ອງຂໍແກ້ໄຂເວລາເຂົ້າ-ອອກວຽກ';

  @override
  String get timeCorrectionHistoryLoadFailed =>
      'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຄຳຮ້ອງແກ້ໄຂເວລາໄດ້.';

  @override
  String get timeCorrectionStatusCancelled => 'ຍົກເລີກແລ້ວ';

  @override
  String get timeCorrectionDetailTitle => 'ລາຍລະອຽດຄຳຮ້ອງ';

  @override
  String get timeCorrectionDetailLoadFailed => 'ບໍ່ສາມາດໂຫຼດລາຍລະອຽດຄຳຮ້ອງໄດ້.';

  @override
  String timeCorrectionSubmittedOn(String date) {
    return 'ວັນທີສົ່ງ: $date';
  }

  @override
  String get timeCorrectionRequestDateLabel => 'ວັນທີຮ້ອງຂໍ';

  @override
  String get timeCorrectionDetailsSection => 'ລາຍລະອຽດການແກ້ໄຂເວລາ';

  @override
  String get timeCorrectionRequestedIn => 'ເວລາເຂົ້າ (Requested)';

  @override
  String get timeCorrectionRequestedOut => 'ເວລາອອກ (Requested)';

  @override
  String timeCorrectionNormalTime(String time) {
    return 'ປົກກະຕິ: $time';
  }

  @override
  String get timeCorrectionTotalHours => 'ລວມຊົ່ວໂມງທີ່ແກ້ໄຂ:';

  @override
  String timeCorrectionHoursValue(String hours) {
    return '$hours ຊົ່ວໂມງ';
  }

  @override
  String get timeCorrectionShiftGroup => 'ກຸ່ມການກວດສອບກະວຽກ (SHIFT)';

  @override
  String get timeCorrectionOtEligible => 'OT Eligible';

  @override
  String timeCorrectionShiftBreak(String hours, int minutes) {
    return '$hours (ພັກ $minutes ນາທີ)';
  }

  @override
  String timeCorrectionShiftType(String type) {
    return 'ປະເພດ: $type';
  }

  @override
  String get timeCorrectionReasonSection => 'ເຫດຜົນ / ລາຍລະອຽດ (Reason)';

  @override
  String get timeCorrectionAttachmentsSection => 'ເອກະສານ ຫຼື ຮູບພາບຕິດຄັດ';

  @override
  String timeCorrectionFileCount(int count) {
    return '$count ໄຟລ໌';
  }

  @override
  String get timeCorrectionEvidencePhoto => 'ຮູບພາບຫຼັກຖານ';

  @override
  String get timeCorrectionEvidenceDocument => 'ເອກະສານຫຼັກຖານ';

  @override
  String get timeCorrectionWorkflowSection =>
      'ຂັ້ນຕອນການອະນຸມັດ (Approval Workflow)';

  @override
  String timeCorrectionStepOf(int current, int total) {
    return 'ຂັ້ນຕອນທີ $current ຈາກ $total';
  }

  @override
  String get timeCorrectionRoleDeptHead => 'ຫົວໜ້າພະແນກ (Dept Head)';

  @override
  String get timeCorrectionRoleHr => 'ຝ່າຍບຸກຄະລາກອນ (HR)';

  @override
  String get timeCorrectionRoleOther => 'ຜູ້ອະນຸມັດ';

  @override
  String get timeCorrectionStepReviewing => 'ກຳລັງກວດສອບ';

  @override
  String timeCorrectionStepWaitingFor(int step) {
    return 'ລໍຖ້າຂັ້ນຕອນ $step';
  }

  @override
  String get timeCorrectionStepApproved => 'ອະນຸມັດແລ້ວ';

  @override
  String get timeCorrectionStepRejected => 'ປະຕິເສດ';

  @override
  String get timeCorrectionApproverUnassigned =>
      'ລໍຖ້າການກຳນົດ (To be assigned)';

  @override
  String timeCorrectionSentAt(String time) {
    return 'ສົ່ງຄຳຮ້ອງເມື່ອ: $time';
  }

  @override
  String timeCorrectionActedAt(String time) {
    return 'ດຳເນີນການເມື່ອ: $time';
  }

  @override
  String get timeCorrectionCancelAction => 'ຍົກເລີກຄຳຮ້ອງ (Cancel Request)';

  @override
  String get timeCorrectionCancelConfirm =>
      'ຕ້ອງການຍົກເລີກຄຳຮ້ອງແກ້ໄຂເວລານີ້ບໍ?';

  @override
  String get timeCorrectionCancelled => 'ຍົກເລີກຄຳຮ້ອງແລ້ວ';

  @override
  String get timeCorrectionCancelFailed => 'ບໍ່ສາມາດຍົກເລີກຄຳຮ້ອງໄດ້.';

  @override
  String get timeCorrectionContactNote =>
      'ຫາກມີຂໍ້ສົງໄສ ສາມາດຕິດຕໍ່ຫົວໜ້າພະແນກ ຫຼື HR ໄດ້ໂດຍກົງ';

  @override
  String get timeCorrectionAttachmentSaved => 'ບັນທຶກໄຟລ໌ແລ້ວ';

  @override
  String get timeCorrectionAttachmentSaveFailed => 'ດາວໂຫຼດໄຟລ໌ບໍ່ສຳເລັດ.';

  @override
  String get timeCorrectionApprovalsMenu => 'ອະນຸມັດແກ້ໄຂເວລາ';

  @override
  String get timeCorrectionApprovalStatusPending => 'ລໍຖ້າກວດສອບ';

  @override
  String timeCorrectionApprovalDepartment(String name) {
    return 'ພະແນກ: $name';
  }

  @override
  String timeCorrectionApprovalShift(String name, String hours) {
    return 'ກະ $name ($hours)';
  }

  @override
  String get timeCorrectionApprovalTypeMissingIn =>
      'ລືມລົງເວລາເຂົ້າ (Missing In)';

  @override
  String get timeCorrectionApprovalTypeMissingOut =>
      'ລືມລົງເວລາອອກ (Missing Out)';

  @override
  String get timeCorrectionApprovalTypeBoth => 'ແກ້ໄຂທັງ ເຂົ້າ ແລະ ອອກ (Both)';

  @override
  String get timeCorrectionApprovalTypeWrongTime => 'ແກ້ໄຂເວລາຜິດ (Wrong Time)';

  @override
  String get timeCorrectionApprovalClockIn => 'ເວລາເຂົ້າ (In)';

  @override
  String get timeCorrectionApprovalClockOut => 'ເວລາອອກ (Out)';

  @override
  String get timeCorrectionApprovalNewIn => 'ເວລາຂໍແກ້ໄຂເຂົ້າ (New In)';

  @override
  String get timeCorrectionApprovalNewOut => 'ເວລາຂໍແກ້ໄຂອອກ (New Out)';

  @override
  String get timeCorrectionApprovalReason => 'ເຫດຜົນ:';

  @override
  String get timeCorrectionApprovalNoAttachment => 'ບໍ່ມີເອກະສານແນບ';

  @override
  String get timeCorrectionApprovalAttachmentSubtitle => 'ເອກະສານຫຼັກຖານແນບ';

  @override
  String get timeCorrectionApprovalViewImage => 'ເບິ່ງຮູບ';

  @override
  String get timeCorrectionApprovalApprove => 'ອະນຸມັດ';

  @override
  String get timeCorrectionApprovalReject => 'ປະຕິເສດ';

  @override
  String get timeCorrectionApprovalsLoadFailed =>
      'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຄຳຮ້ອງແກ້ໄຂເວລາໄດ້.';

  @override
  String get approvalsMenu => 'ການອະນຸມັດ';

  @override
  String get apprApproveConfirmTitle => 'ອະນຸມັດຄຳຮ້ອງນີ້ບໍ?';

  @override
  String get apprApproveNoteHint => 'ໝາຍເຫດ (ບໍ່ບັງຄັບ)';

  @override
  String get apprApproveLastStepHint =>
      'ນີ້ແມ່ນຂັ້ນສຸດທ້າຍ: ວັນລາຈະຖືກຫັກອອກຈາກຍອດຄົງເຫຼືອທັນທີ.';

  @override
  String get apprApprovedToast => 'ອະນຸມັດແລ້ວ';

  @override
  String get apprRejectedToast => 'ປະຕິເສດແລ້ວ';

  @override
  String get apprRequestNotFound => 'ບໍ່ພົບຄຳຮ້ອງນີ້';

  @override
  String get apprSectionTeam => 'ທີມຂອງຂ້ອຍ';

  @override
  String get apprTeamLeave => 'ລາພັກ';

  @override
  String get apprTeamCorrections => 'ລືມລົງເວລາ';

  @override
  String get apprTeamEmpty => 'ບໍ່ມີຄຳຮ້ອງຂອງທີມ';

  @override
  String get apprReasonRequired => 'ກະລຸນາຂຽນເຫດຜົນ';

  @override
  String get otApprovedToast => 'ອະນຸມັດໂອທີແລ້ວ';

  @override
  String get otRejectedToast => 'ປະຕິເສດໂອທີແລ້ວ';

  @override
  String get otCancelApprovedAction => 'ຍົກເລີກໂອທີ';

  @override
  String get otCancelApprovedConfirm =>
      'ຍົກເລີກໂອທີທີ່ອະນຸມັດແລ້ວນີ້ບໍ? ພະນັກງານຈະໄດ້ຮັບແຈ້ງເຕືອນ.';

  @override
  String get apprSectionOt => 'ໂອທີ';

  @override
  String get apprOtWaitingEmpty => 'ບໍ່ມີໂອທີລໍຖ້າທ່ານ';

  @override
  String apprWaitingHours(int hours) {
    return 'ລໍຖ້າ $hours ຊົ່ວໂມງ';
  }

  @override
  String get apprAlreadyDecided => 'ມີຄົນຕັດສິນຄຳຮ້ອງນີ້ແລ້ວ';

  @override
  String get apprCannotDecideOwn => 'ທ່ານຕັດສິນຄຳຮ້ອງຂອງຕົນເອງບໍ່ໄດ້';

  @override
  String get apprAnotherApprover => 'ຂັ້ນຕອນນີ້ຕ້ອງໃຫ້ຜູ້ອະນຸມັດຄົນອື່ນຕັດສິນ';

  @override
  String get apprApproveCheckinFirst =>
      'ກະລຸນາອະນຸມັດການລົງເວລາເຂົ້າຂອງຄົນນີ້ກ່ອນ';

  @override
  String get apprCheckinNotApproved =>
      'ການລົງເວລາເຂົ້າຖືກປະຕິເສດ ຫຼື ຍົກເລີກແລ້ວ, ລາຍການນີ້ປະຕິເສດໄດ້ຢ່າງດຽວ';

  @override
  String get apprEmployeeLabel => 'ພະນັກງານ';

  @override
  String get uploadTakePhoto => 'ຖ່າຍຮູບ';

  @override
  String get uploadPickPhoto => 'ເລືອກຈາກຮູບພາບ';

  @override
  String get uploadPickFile => 'ເລືອກໄຟລ໌';

  @override
  String get uploadInProgress => 'ກຳລັງອັບໂຫຼດ…';

  @override
  String get uploadFileTooLarge => 'ໄຟລ໌ໃຫຍ່ເກີນ 5 MB';

  @override
  String get uploadInvalidFile => 'ອ່ານໄຟລ໌ບໍ່ໄດ້, ກະລຸນາເລືອກໃໝ່';

  @override
  String get uploadStorageUnavailable =>
      'ຕອນນີ້ອັບໂຫຼດໄຟລ໌ບໍ່ໄດ້, ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ';

  @override
  String get uploadPermissionDenied =>
      'ກະລຸນາອະນຸຍາດໃຫ້ແອັບໃຊ້ກ້ອງ ຫຼື ຮູບພາບ ໃນການຕັ້ງຄ່າໂທລະສັບ';

  @override
  String get approvalsLeaveTab => 'ລາພັກ';

  @override
  String get approvalsTimeCorrectionTab => 'ລືມລົງເວລາ';

  @override
  String get offsiteTitle => 'ລົງເວລານອກພື້ນທີ່';

  @override
  String get offsiteNoticeTitle => 'ການລົງເວລານອກພື້ນທີ່ວຽກ';

  @override
  String get offsiteNoticeBody =>
      'ຕຳແໜ່ງຂອງທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ. ກະລຸນາແນບຮູບຖ່າຍ ແລະ ເຫດຜົນ: ຖ້າທ່ານມີສິດເຮັດວຽກນອກພື້ນທີ່ ລະບົບຈະບັນທຶກເວລາທັນທີ, ຖ້າບໍ່ມີ ຝ່າຍບຸຄຄົນຈະພິຈາລະນາອະນຸມັດກ່ອນ';

  @override
  String get offsiteMethodLabel => 'ປະເພດການລົງເວລາ';

  @override
  String get offsiteMethodCheckIn => 'ລົງເວລາເຂົ້າ';

  @override
  String get offsiteMethodCheckOut => 'ລົງເວລາອອກ';

  @override
  String get offsiteLocationLabel => 'ຕຳແໜ່ງຂອງທ່ານ';

  @override
  String get offsiteLocating => 'ກຳລັງອ່ານຕຳແໜ່ງ…';

  @override
  String offsiteAccuracy(int metres) {
    return 'ຄວາມຄາດເຄື່ອນປະມານ $metres ແມັດ';
  }

  @override
  String get offsiteReasonLabel => 'ເຫດຜົນ';

  @override
  String get offsiteReasonHint => 'ລະບຸເຫດຜົນທີ່ລົງເວລາຢູ່ນອກພື້ນທີ່';

  @override
  String get offsiteReasonRequired => 'ກະລຸນາລະບຸເຫດຜົນ';

  @override
  String offsiteReasonTooLong(int max) {
    return 'ເຫດຜົນຕ້ອງບໍ່ເກີນ $max ຕົວອັກສອນ';
  }

  @override
  String get offsitePhotoLabel => 'ຮູບຖ່າຍ';

  @override
  String get offsitePhotoTitle => 'ກົດເພື່ອຖ່າຍຮູບສະຖານທີ່ທີ່ທ່ານຢູ່';

  @override
  String get offsitePhotoHint =>
      'ຕ້ອງແນບຮູບຖ່າຍ: JPG, PNG, HEIC ຫຼື WEBP\n(ສູງສຸດ 5MB)';

  @override
  String get offsitePhotoRequired => 'ກະລຸນາແນບຮູບຖ່າຍ';

  @override
  String get offsiteSubmit => 'ສົ່ງຄຳຮ້ອງ';

  @override
  String get offsiteSubmitApproved => 'ບັນທຶກການລົງເວລານອກພື້ນທີ່ແລ້ວ';

  @override
  String get offsiteSubmitPending => 'ສົ່ງຄຳຮ້ອງແລ້ວ — ລໍຖ້າການອະນຸມັດ';

  @override
  String get ruleOutsideWorkArea =>
      'ທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ ການລົງເວລານີ້ຈຶ່ງບໍ່ຜ່ານການຕວດສອບ';

  @override
  String get ruleOffsiteRequestExists =>
      'ທ່ານມີຄຳຮ້ອງລົງເວລານອກພື້ນທີ່ຂອງຊ່ວງເວລານີ້ຢູ່ແລ້ວ ກະລຸນາລໍຖ້າຜົນການອະນຸມັດ';

  @override
  String get ruleTooEarlyCheckin => 'ຍັງບໍ່ເຖິງເວລາລົງເວລາເຂົ້າ';

  @override
  String ruleTooEarlyCheckinAt(String time) {
    return 'ຍັງບໍ່ເຖິງເວລາລົງເວລາເຂົ້າ — ເປີດໃຫ້ລົງເວລາຕອນ $time';
  }

  @override
  String get approvalsOffsiteTab => 'ລົງເວລານອກພື້ນທີ່';

  @override
  String get offsiteHistoryEmpty => 'ບໍ່ມີຄຳຮ້ອງລົງເວລານອກພື້ນທີ່';

  @override
  String get attMyRequestsMenu => 'ຄຳຮ້ອງຂອງຂ້ອຍ';

  @override
  String get attMyRequestsTitle => 'ຄຳຮ້ອງຂອງຂ້ອຍ';

  @override
  String get attOffsiteTab => 'ລົງເວລານອກພື້ນທີ່';

  @override
  String get attView => 'ເບິ່ງ';

  @override
  String get attCorrectionTab => 'ລືມລົງເວລາ';

  @override
  String get attCorrectionResult => 'ຜົນຫຼັງແກ້ໄຂ';

  @override
  String get attCorrectionRequested => 'ເວລາທີ່ຂໍ';

  @override
  String get attOffsiteDetailTitle => 'ຄຳຮ້ອງລົງເວລານອກພື້ນທີ່';

  @override
  String get attCheckinPendingApproval =>
      'ການລົງເວລາເຂົ້າຂອງທ່ານຍັງລໍຖ້າອະນຸມັດຢູ່';

  @override
  String get offsiteHistoryLoadFailed =>
      'ບໍ່ສາມາດໂຫຼດຄຳຮ້ອງລົງເວລານອກພື້ນທີ່ໄດ້.';

  @override
  String get offsiteOfferTitle => 'ຢູ່ນອກພື້ນທີ່ວຽກ';

  @override
  String get offsiteOfferClockIn =>
      'ທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ ການລົງເວລາເຂົ້າຖືກບັນທຶກແຕ່ບໍ່ຜ່ານການຕວດສອບ. ຕ້ອງການຍື່ນຄຳຮ້ອງລົງເວລາເຂົ້ານອກພື້ນທີ່ຈາກຈຸດນີ້ບໍ?';

  @override
  String get offsiteOfferClockOut =>
      'ທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ ການລົງເວລາອອກຖືກບັນທຶກແຕ່ບໍ່ຜ່ານການຕວດສອບ. ຕ້ອງການຍື່ນຄຳຮ້ອງລົງເວລາອອກນອກພື້ນທີ່ຈາກຈຸດນີ້ບໍ?';

  @override
  String get offsiteOfferRefusedClockIn =>
      'ທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ ການລົງເວລາເຂົ້າຈຶ່ງບໍ່ຖືກຮັບ ແລະ ບໍ່ມີການບັນທຶກ. ຕ້ອງການຍື່ນຄຳຮ້ອງລົງເວລາເຂົ້ານອກພື້ນທີ່ຈາກຈຸດນີ້ບໍ?';

  @override
  String get offsiteOfferRefusedClockOut =>
      'ທ່ານຢູ່ນອກພື້ນທີ່ວຽກທັງໝົດ ການລົງເວລາອອກຈຶ່ງບໍ່ຖືກຮັບ ແລະ ບໍ່ມີການບັນທຶກ. ຕ້ອງການຍື່ນຄຳຮ້ອງລົງເວລາອອກນອກພື້ນທີ່ຈາກຈຸດນີ້ບໍ?';

  @override
  String get offsiteOfferConfirm => 'ຍື່ນຄຳຮ້ອງລົງເວລານອກພື້ນທີ່';

  @override
  String get offsiteCancelAction => 'ຍົກເລີກຄຳຮ້ອງ';

  @override
  String get offsiteCancelConfirm =>
      'ຕ້ອງການຍົກເລີກຄຳຮ້ອງລົງເວລານອກພື້ນທີ່ນີ້ບໍ? ທ່ານຈະຕ້ອງຍື່ນຄຳຮ້ອງໃໝ່ອີກຄັ້ງ.';

  @override
  String get offsiteCancelled => 'ຍົກເລີກຄຳຮ້ອງແລ້ວ';

  @override
  String get offsiteCannotCancel =>
      'ຄຳຮ້ອງນີ້ຍົກເລີກບໍ່ໄດ້ແລ້ວ — ຖືກພິຈາລະນາໄປແລ້ວ.';

  @override
  String get offsiteApprovalScannedAt => 'ເວລາທີ່ລົງເວລາ';

  @override
  String get offsiteApprovalPosition => 'ຕຳແໜ່ງ';

  @override
  String get offsiteApprovalNoFix => 'ບໍ່ມີຕຳແໜ່ງ';

  @override
  String get offsiteApprovalNoScanDate => 'ບໍ່ມີວັນທີລົງເວລາ';

  @override
  String get offsiteApprovalsLoadFailed =>
      'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຄຳຮ້ອງລົງເວລານອກພື້ນທີ່ໄດ້.';

  @override
  String get offsiteApprovalsEmpty => 'ບໍ່ມີຄຳຮ້ອງລົງເວລານອກພື້ນທີ່';

  @override
  String get offsiteTooEarlyCheckin =>
      'ອະນຸມັດແລ້ວ ແຕ່ຍັງບໍ່ເຖິງເວລາລົງເວລາເຂົ້າ — ຍັງບໍ່ໄດ້ບັນທຶກເວລາ';

  @override
  String get errorWrongServer => 'ແອັບນີ້ເຊື່ອມຕໍ່ຜິດບ່ອນ. ກະລຸນາອັບເດດແອັບ.';

  @override
  String get errorTenantNotFound => 'ບໍ່ພົບບໍລິສັດນີ້ໃນລະບົບ.';

  @override
  String get errorTenantInactive =>
      'ບໍລິສັດຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ HR.';

  @override
  String get errorTenantUnavailable =>
      'ລະບົບຂອງບໍລິສັດຍັງບໍ່ພ້ອມ. ກະລຸນາລອງໃໝ່ໃນອີກບໍ່ເທົ່າໃດນາທີ.';

  @override
  String get errorTenantMismatch =>
      'ບັນຊີນີ້ເປັນຂອງບໍລິສັດອື່ນ. ກະລຸນາອອກຈາກລະບົບ ແລ້ວເຂົ້າໃໝ່.';

  @override
  String get errorModuleNotActive => 'ບໍລິສັດຂອງທ່ານຍັງບໍ່ໄດ້ເປີດໃຊ້ສ່ວນນີ້.';

  @override
  String get errorRateLimited =>
      'ສົ່ງຄຳຂໍຖີ່ເກີນໄປ. ກະລຸນາລໍຖ້າໜຶ່ງນາທີ ແລ້ວລອງໃໝ່.';

  @override
  String get passwordChangedSignInAgain =>
      'ປ່ຽນລະຫັດຜ່ານແລ້ວ. ກະລຸນາເຂົ້າສູ່ລະບົບດ້ວຍລະຫັດຜ່ານໃໝ່.';

  @override
  String tooManyAttemptsWait(int minutes) {
    return 'ພະຍາຍາມຫຼາຍເກີນໄປ. ລອງໃໝ່ໄດ້ໃນອີກ $minutes ນາທີ.';
  }

  @override
  String ruleClockOutBeforeClockInAt(String time) {
    return 'ທ່ານລົງເວລາເຂົ້າຕອນ $time. ລົງເວລາອອກກ່ອນນັ້ນບໍ່ໄດ້.';
  }

  @override
  String get ruleClockOutBeforeClockIn =>
      'ລົງເວລາອອກກ່ອນເວລາລົງເວລາເຂົ້າບໍ່ໄດ້.';

  @override
  String get ruleOtChanged => 'ໂອທີຂອງທ່ານຫາກໍ່ປ່ຽນ. ກະລຸນາລອງໃໝ່.';

  @override
  String ruleAfterCheckoutWindowAt(String time) {
    return 'ເລີຍເວລາລົງເວລາອອກແລ້ວ (ເປີດຮອດ $time).';
  }

  @override
  String ruleOutsideShiftHoursAt(String time) {
    return 'ໝົດເວລາລົງເວລາເຂົ້າຂອງມື້ນີ້ແລ້ວ (ກະສຸດທ້າຍຈົບ $time).';
  }

  @override
  String get attendanceAbsentStatus => 'ຂາດວຽກ';

  @override
  String get attendanceIncompleteStatus => 'ບໍ່ຄົບ';

  @override
  String get attendanceHalfDayStatus => 'ເຄິ່ງມື້';

  @override
  String get leaveDays => 'ວັນລາພັກ';

  @override
  String attWorkingDaysBase(int days) {
    return 'ຈາກ $days ມື້ເຮັດວຽກ';
  }

  @override
  String get attOvertimeTileLabel => 'ໂອທີ';

  @override
  String attOvertimeHoursLine(String hours) {
    return 'ໂອທີ $hours ຊົ່ວໂມງ';
  }

  @override
  String get attSummaryLoadFailed => 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການລົງເວລາໄດ້.';

  @override
  String get profileLoadFailed => 'ບໍ່ສາມາດໂຫຼດໂປຣຟາຍໄດ້.';

  @override
  String get leaveModeRange => 'ຊ່ວງວັນທີ';

  @override
  String get leaveModeSeparateDays => 'ເລືອກເປັນມື້ໆ';

  @override
  String get leaveRangeSkipsDaysOff => 'ບໍ່ນັບວັນພັກຂອງບໍລິສັດ.';

  @override
  String get leaveRangeCountByServer => 'ລະບົບຈະນັບວັນໃຫ້ຫຼັງຈາກສົ່ງ.';

  @override
  String get leaveDayOffLegend => 'ວັນພັກຂອງບໍລິສັດ';

  @override
  String get leaveAllDaysOff => 'ວັນທີ່ເລືອກແມ່ນວັນພັກຂອງບໍລິສັດທັງໝົດ.';

  @override
  String get leaveDaysOffLoadFailed => 'ໂຫຼດວັນພັກຂອງບໍລິສັດບໍ່ໄດ້.';

  @override
  String get leavePickRangeStart => 'ເລືອກວັນທຳອິດ';

  @override
  String get leavePickRangeEnd => 'ເລືອກວັນສຸດທ້າຍ';

  @override
  String get leaveChanged =>
      'ຄຳຮ້ອງລານີ້ຫາກໍ່ມີການປ່ຽນແປງ. ໂຫຼດຂໍ້ມູນໃໝ່ແລ້ວ, ກະລຸນາກວດເບິ່ງແລ້ວລອງອີກຄັ້ງ.';

  @override
  String get leaveApprovalInsufficientBalance =>
      'ພະນັກງານຄົນນີ້ມີວັນລາຄົງເຫຼືອບໍ່ພຽງພໍສຳລັບການລານີ້. ໃຫ້ HR ເພີ່ມວັນລາ ຫຼື ປະຕິເສດຄຳຮ້ອງນີ້.';

  @override
  String get leaveApprovalNoLongerWaiting =>
      'ຄຳຮ້ອງນີ້ບໍ່ໄດ້ລໍຖ້າການອະນຸມັດແລ້ວ (ມີຄົນຕັດສິນແລ້ວ ຫຼື ຖືກຍົກເລີກ).';

  @override
  String get leaveRequestGone => 'ຄຳຮ້ອງນີ້ບໍ່ມີແລ້ວ ຫຼື ທ່ານບໍ່ມີສິດເບິ່ງ.';

  @override
  String get leaveRequestPendingBanner =>
      'ທ່ານມີຄຳຮ້ອງລາທີ່ລໍຖ້າອະນຸມັດຢູ່. ສົ່ງຄຳຮ້ອງໃໝ່ໄດ້ຫຼັງຈາກຄຳຮ້ອງນັ້ນຖືກຕັດສິນແລ້ວ.';

  @override
  String get leaveViewRequest => 'ເບິ່ງຄຳຮ້ອງ';

  @override
  String get leaveCancelApprovedConfirm =>
      'ການລານີ້ອະນຸມັດແລ້ວ. ຍົກເລີກ ແລະ ຄືນວັນລາເຂົ້າຍອດຄົງເຫຼືອບໍ?';

  @override
  String get leaveRuleTypeInactive =>
      'ປະເພດການລານີ້ຖືກປິດໃຊ້ງານແລ້ວ ກະລຸນາເລືອກປະເພດອື່ນ.';

  @override
  String get leaveRuleTypeNotFound =>
      'ບໍ່ພົບປະເພດການລານີ້ແລ້ວ ກະລຸນາເລືອກປະເພດອື່ນ.';

  @override
  String get leaveRuleGenderNotAllowed =>
      'ປະເພດການລານີ້ບໍ່ສາມາດໃຊ້ກັບເພດຂອງທ່ານໄດ້.';

  @override
  String get leaveRuleGenderNotSet =>
      'ຂໍ້ມູນພະນັກງານຂອງທ່ານຍັງບໍ່ໄດ້ລະບຸເພດ ກະລຸນາຕິດຕໍ່ HR ເພື່ອລະບຸ.';

  @override
  String get leaveRuleNotYetAvailable =>
      'ທ່ານຍັງບໍ່ສາມາດໃຊ້ປະເພດການລານີ້ໄດ້ ກະລຸນາສອບຖາມ HR.';

  @override
  String leaveRuleNotYetAvailableFrom(String date) {
    return 'ປະເພດການລານີ້ໃຊ້ໄດ້ສຳລັບວັນລາຕັ້ງແຕ່ວັນທີ $date ເປັນຕົ້ນໄປ.';
  }

  @override
  String get leaveRuleHalfDayNotAllowed =>
      'ປະເພດການລານີ້ບໍ່ສາມາດລາເຄິ່ງມື້ໄດ້.';

  @override
  String get leaveRuleNoticeTooShort =>
      'ການລາປະເພດນີ້ຕ້ອງຂໍລ່ວງໜ້າຫຼາຍກວ່ານີ້.';

  @override
  String leaveRuleNoticeTooShortBy(String days, String date) {
    return 'ການລາປະເພດນີ້ຕ້ອງຂໍລ່ວງໜ້າຢ່າງໜ້ອຍ $days ວັນ. ວັນທຳອິດທີ່ລາໄດ້ແມ່ນ $date.';
  }

  @override
  String get leaveRuleTooLong =>
      'ຈຳນວນວັນລາຕິດຕໍ່ກັນເກີນກວ່າທີ່ປະເພດການລານີ້ອະນຸຍາດ. ວັນພັກທີ່ຢູ່ລະຫວ່າງກາງກໍນັບລວມ.';

  @override
  String leaveRuleTooLongBy(String max) {
    return 'ປະເພດການລານີ້ລາຕິດຕໍ່ກັນໄດ້ສູງສຸດ $max ວັນ. ວັນພັກທີ່ຢູ່ລະຫວ່າງກາງກໍນັບລວມ.';
  }

  @override
  String get leaveRuleSpanTooLong =>
      'ວັນທຳອິດ ແລະ ວັນສຸດທ້າຍຂອງຄຳຮ້ອງດຽວຕ້ອງຫ່າງກັນບໍ່ເກີນ 1 ປີ.';

  @override
  String get leaveStartedContactHr =>
      'ການລານີ້ເລີ່ມແລ້ວ ຈຶ່ງຍົກເລີກໃນແອັບບໍ່ໄດ້. ຖ້າຕ້ອງການປ່ຽນ, ກະລຸນາຕິດຕໍ່ HR.';

  @override
  String get listLoadMoreFailed => 'ໂຫຼດເພີ່ມບໍ່ໄດ້.';

  @override
  String get leaveOwnRequestNoActions =>
      'ນີ້ແມ່ນຄຳຮ້ອງຂອງທ່ານເອງ. ຕ້ອງໃຫ້ຄົນອື່ນເປັນຜູ້ຕັດສິນ.';

  @override
  String get leaveDecidedByMeApproved => 'ທີ່ຂ້ອຍອະນຸມັດ';

  @override
  String get leaveDecidedByMeRejected => 'ທີ່ຂ້ອຍປະຕິເສດ';

  @override
  String leaveWaitingForStep(String role) {
    return 'ລໍຖ້າ$role';
  }

  @override
  String get salaryStatusApproved => 'ອະນຸມັດແລ້ວ';

  @override
  String get salaryPaymentFailed => 'ໂອນເງິນບໍ່ສຳເລັດ';

  @override
  String get salaryPaymentFailedContactHr =>
      'ການໂອນເງິນບໍ່ສຳເລັດ, ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ';

  @override
  String get payslipLineOvertime => 'ຄ່າລ່ວງເວລາ (ໂອທີ)';

  @override
  String get payslipLineLate => 'ຫັກມາວຽກຊ້າ';

  @override
  String get payslipLineAbsentLate => 'ຫັກມື້ມາຊ້າເກີນກຳນົດ';

  @override
  String get payslipLineEarlyOut => 'ຫັກອອກວຽກກ່ອນເວລາ';

  @override
  String get payslipLineMissedPart => 'ຫັກບໍ່ໄດ້ເຂົ້າບາງຊ່ວງຂອງກະ';

  @override
  String get payslipLineAbsence => 'ຫັກຂາດວຽກ';

  @override
  String get payslipLineUnpaidLeave => 'ລາພັກບໍ່ໄດ້ຮັບເງິນ';

  @override
  String get payslipLineAttendanceSettlement => 'ປັບຍອດການເຂົ້າວຽກວັນກ່ອນ';

  @override
  String get payslipLineLoan => 'ຫັກເງິນກູ້';

  @override
  String payslipCaptionHoursMinutes(String h, String m) {
    return '$h ຊມ $m ນາທີ';
  }

  @override
  String payslipCaptionMinutes(String m) {
    return '$m ນາທີ';
  }

  @override
  String payslipCaptionTimes(String n) {
    return '$n ເທື່ອ';
  }

  @override
  String payslipCaptionDays(String n) {
    return '$n ວັນ';
  }

  @override
  String payslipCaptionHours(String n) {
    return '$n ຊົ່ວໂມງ';
  }

  @override
  String get payslipSectionAttendance => 'ລາຍການຫັກ — ການເຂົ້າວຽກ';

  @override
  String get payslipSectionStatutory => 'ລາຍການຫັກ — ຕາມກົດໝາຍ';

  @override
  String get payslipSectionOther => 'ລາຍການຫັກອື່ນໆ';

  @override
  String get payslipNotAvailable => 'ໃບເງິນເດືອນນີ້ບໍ່ມີແລ້ວ';

  @override
  String get back => 'ກັບຄືນ';

  @override
  String get payslipOtDetailsTitle => 'ລາຍລະອຽດໂອທີ';

  @override
  String get payslipOtNotPaidNote =>
      'ບໍ່ໄດ້ຈ່າຍເປັນໂອທີ: ເວລານີ້ຢູ່ໃນກະວຽກ ຫຼື ບໍ່ໄດ້ສະແກນ';

  @override
  String payslipOtKipPerHour(String amount) {
    return '$amount ກີບ/ຊມ';
  }

  @override
  String get payslipOtTotal => 'ລວມ';

  @override
  String get payslipPdfTitle => 'ໃບເງິນເດືອນ (PDF)';

  @override
  String get payslipPdfLoading => 'ກຳລັງສ້າງ PDF…';

  @override
  String get payslipPdfMakeFailed => 'ສ້າງໄຟລ໌ PDF ບໍ່ສຳເລັດ, ກະລຸນາລອງໃໝ່';

  @override
  String get payslipPdfShare => 'ແບ່ງປັນ';

  @override
  String get payslipPdfShareFailed => 'ແບ່ງປັນໄຟລ໌ PDF ບໍ່ສຳເລັດ';

  @override
  String get otDisabled => 'ບໍລິສັດຍັງບໍ່ໄດ້ເປີດໃຊ້ໂອທີ.';

  @override
  String get otNotEligible =>
      'ທ່ານຍັງບໍ່ມີສິດຂໍໂອທີ. ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ.';

  @override
  String get otTooFarBack => 'ວັນທີນີ້ຍ້ອນຫຼັງເກີນກວ່າທີ່ບໍລິສັດອະນຸຍາດ.';

  @override
  String get otOverlap => 'ເວລານີ້ທັບກັບໂອທີອື່ນຂອງທ່ານ.';

  @override
  String get otOverlapsShift =>
      'ເວລານີ້ທັບກັບກະວຽກຂອງທ່ານ. ໂອທີຕ້ອງຢູ່ນອກກະວຽກ.';

  @override
  String get otEmployeeLeft =>
      'ຂໍໂອທີວັນນີ້ບໍ່ໄດ້. ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ.';

  @override
  String get otAlreadyDecided =>
      'ຄຳຂໍນີ້ມີການຕັດສິນແລ້ວ, ປ່ຽນບໍ່ໄດ້. ກະລຸນາຖາມຜູ້ອະນຸມັດ ຫຼື ຝ່າຍບຸກຄະລາກອນ.';

  @override
  String get otAnnounced =>
      'ໂອທີນີ້ມາຈາກປະກາດຂອງຝ່າຍບຸກຄະລາກອນ, ແກ້ເວລາບໍ່ໄດ້. ຖ້າບໍ່ໄປ ໃຫ້ຍົກເລີກ.';

  @override
  String get otFull => 'ບ່ອນເຕັມແລ້ວ.';

  @override
  String get otJoinClosed => 'ປິດຮັບແລ້ວ.';

  @override
  String get otStepChanged => 'ຄຳຂໍນີ້ຫາກໍ່ຖືກອັບເດດ — ກະລຸນາກວດຄືນ.';

  @override
  String get otStarted => 'ໂອທີນີ້ເລີ່ມແລ້ວ. ມີແຕ່ຝ່າຍບຸກຄະລາກອນທີ່ຍົກເລີກໄດ້.';

  @override
  String get otAlreadyPaid =>
      'ເງິນເດືອນທີ່ອະນຸມັດແລ້ວໄດ້ຈ່າຍໂອທີນີ້, ຍົກເລີກບໍ່ໄດ້.';

  @override
  String get otPaidByHand =>
      'ຝ່າຍບຸກຄະລາກອນໝາຍວ່າຈ່າຍເງິນສົດແລ້ວ. ກະລຸນາຖາມຝ່າຍບຸກຄະລາກອນ.';

  @override
  String get otCancelForbidden => 'ຄຳຂໍທີ່ລໍຖ້າ ໃຫ້ກົດປະຕິເສດແທນ.';

  @override
  String get otMenu => 'ໂອທີ';

  @override
  String get otListEmpty => 'ຍັງບໍ່ມີຄຳຂໍໂອທີ';

  @override
  String get otListLoadFailed => 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໂອທີໄດ້.';

  @override
  String get otAllMonths => 'ທຸກເດືອນ';

  @override
  String get otNextDay => '(ມື້ຖັດໄປ)';

  @override
  String get otFromPost => 'ຈາກປະກາດ';

  @override
  String get otDidNotCome => 'ບໍ່ໄດ້ມາ';

  @override
  String get otPickMonth => 'ເລືອກເດືອນ';

  @override
  String otWaitingFor(String role) {
    return 'ລໍຖ້າ: $role';
  }

  @override
  String get otPiecesSetOnApproval =>
      'ຝ່າຍບຸກຄະລາກອນຈະກຳນົດເວລາ ແລະ ຄ່າຈ້າງ ຕອນອະນຸມັດ';

  @override
  String get otAgreementNoteLabel => 'ໝາຍເຫດຈາກຝ່າຍບຸກຄະລາກອນ';

  @override
  String get otNoteDidNotCome => 'ບໍ່ໄດ້ມາ: ບໍ່ມີເວລາສະແກນໃນຊ່ວງໂອທີ';

  @override
  String get otNotePaidByHand =>
      'ຝ່າຍບຸກຄະລາກອນຈ່າຍເປັນເງິນສົດແລ້ວ — ບໍ່ຢູ່ໃນໃບເງິນເດືອນ';

  @override
  String get otNoteHrOnly => 'ວັນນີ້ເປັນວັນລາ: ຝ່າຍບຸກຄະລາກອນເປັນຜູ້ອະນຸມັດ';

  @override
  String get otNoteFromPost => 'ຈາກປະກາດຂອງຝ່າຍບຸກຄະລາກອນ';

  @override
  String get otPaidOnPayslip => 'ຊົ່ວໂມງ ແລະ ເງິນທີ່ຈ່າຍຈິງ ຢູ່ໃນໃບເງິນເດືອນ';

  @override
  String get otRequestGone => 'ຄຳຂໍໂອທີນີ້ບໍ່ມີແລ້ວ';

  @override
  String get otAsk => 'ຂໍໂອທີ';

  @override
  String get otDateLabel => 'ວັນທີ';

  @override
  String get otStartLabel => 'ເວລາເລີ່ມ';

  @override
  String get otEndLabel => 'ເວລາສິ້ນສຸດ';

  @override
  String get otReasonOptional => 'ເຫດຜົນ (ບໍ່ບັງຄັບ)';

  @override
  String get otPastDateWarning =>
      'ວັນທີນີ້ຜ່ານມາແລ້ວ. ເວລາທີ່ເຮັດກ່ອນໂອທີຖືກອະນຸມັດ ອາດໄດ້ຈ່າຍໜ້ອຍ ຫຼື ບໍ່ໄດ້ຈ່າຍ, ເພາະສະແກນເປັນໂອທີບໍ່ໄດ້.';

  @override
  String get otEndEqualsStart => 'ເວລາສິ້ນສຸດຕ້ອງບໍ່ເທົ່າກັບເວລາເລີ່ມ';

  @override
  String get otAskSent => 'ສົ່ງຄຳຂໍໂອທີແລ້ວ';

  @override
  String get otClockHintsTitle => 'ວິທີສະແກນໂອທີ';

  @override
  String get otClockHintAfterShift =>
      'ໂອທີຕໍ່ຈາກກະວຽກ: ຢ່າສະແກນອອກຕອນເລີກກະ. ສະແກນອອກເທື່ອດຽວ ຕອນໂອທີເລີກ.';

  @override
  String get otClockHintWindow =>
      'ໂອທີມີຊ່ວງຫ່າງ, ໃນວັນພັກ ຫຼື ວັນລາ: ສະແກນເຂົ້າໄດ້ຕັ້ງແຕ່ 30 ນາທີກ່ອນເລີ່ມ, ສະແກນອອກບໍ່ເກີນ 60 ນາທີຫຼັງເລີກ.';

  @override
  String get otClockHintTwoOts =>
      'ໂອທີສອງອັນຫ່າງກັນບໍ່ເຖິງ 60 ນາທີ: ສະແກນເຂົ້າເທື່ອດຽວ, ການສະແກນອອກເທື່ອສຸດທ້າຍປິດທັງສອງ.';

  @override
  String get otClockHintThisApp =>
      'ສະແກນໂອທີດ້ວຍແອັບນີ້ ບໍ່ແມ່ນເຄື່ອງສະແກນທີ່ປະຕູ. ລືມສະແກນອອກ: ໂອທີນັ້ນບໍ່ໄດ້ຈ່າຍ.';

  @override
  String get otEditAction => 'ແກ້ໄຂ';

  @override
  String get otCancelAction => 'ຍົກເລີກ';

  @override
  String get otAskApproverToChange =>
      'ຢາກປ່ຽນ ຫຼື ຍົກເລີກ? ກະລຸນາຖາມຜູ້ອະນຸມັດ ຫຼື ຝ່າຍບຸກຄະລາກອນ.';

  @override
  String get otEditRestartsApproval =>
      'ເມື່ອບັນທຶກ, ຄຳຂໍຈະເລີ່ມອະນຸມັດໃໝ່ຕັ້ງແຕ່ຕົ້ນ.';

  @override
  String get otSaved => 'ບັນທຶກແລ້ວ';

  @override
  String get otSaveAction => 'ບັນທຶກ';

  @override
  String get otCancelConfirm => 'ຍົກເລີກຄຳຂໍໂອທີນີ້ບໍ?';

  @override
  String get otCancelledToast => 'ຍົກເລີກຄຳຂໍໂອທີແລ້ວ';

  @override
  String get otApprovedCancelledToast => 'ຍົກເລີກໂອທີແລ້ວ';

  @override
  String get otPostsTitle => 'ປະກາດໂອທີ';

  @override
  String otPostPlacesLeft(int n) {
    return 'ຍັງເຫຼືອ $n ບ່ອນ';
  }

  @override
  String get otPostNoLimit => 'ບໍ່ຈຳກັດຈຳນວນ';

  @override
  String otPostCloses(String time) {
    return 'ປິດຮັບ $time';
  }

  @override
  String get otPostJoin => 'ເຂົ້າຮ່ວມ';

  @override
  String get otPostJoinConfirm => 'ຂໍເຂົ້າຮ່ວມໂອທີນີ້ບໍ?';

  @override
  String get otPostWaitingHr => 'ລໍຖ້າຝ່າຍບຸກຄະລາກອນ';

  @override
  String get otPostAccepted => 'ຮັບແລ້ວ';

  @override
  String get otPostFull => 'ເຕັມແລ້ວ';

  @override
  String get otPostCannotJoin => 'ເຂົ້າຮ່ວມບໍ່ໄດ້ຕອນນີ້';

  @override
  String get otPostJoinSent => 'ສົ່ງຄຳຂໍເຂົ້າຮ່ວມແລ້ວ, ລໍຖ້າຝ່າຍບຸກຄະລາກອນ';

  @override
  String get otPostGone => 'ປະກາດນີ້ບໍ່ມີແລ້ວ ຫຼື ບໍ່ແມ່ນຂອງພະແນກທ່ານ.';

  @override
  String get otPostsEmpty => 'ບໍ່ມີປະກາດໂອທີສຳລັບພະແນກຂອງທ່ານ';

  @override
  String attOffsiteCheckinWaiting(String time) {
    return 'ລົງເວລາເຂົ້ານອກພື້ນທີ່ເວລາ $time: ລໍຖ້າອະນຸມັດ';
  }

  @override
  String get attOffsiteBothWaiting =>
      'ລົງເວລາເຂົ້າ ແລະ ອອກ ນອກພື້ນທີ່: ລໍຖ້າອະນຸມັດ';

  @override
  String get attCorrectionDuplicate => 'ທ່ານຂໍແກ້ໄຂມື້ ແລະ ຊ່ວງກະນີ້ແລ້ວ';

  @override
  String attCorrectionTooEarly(String time) {
    return 'ລົງເວລາເຂົ້າຂອງກະນັ້ນເລີ່ມໄດ້ເວລາ $time';
  }

  @override
  String attCorrectionOutOfRange(String earliest, String latest) {
    return 'ເລືອກໄດ້ແຕ່ວັນທີ $earliest–$latest';
  }

  @override
  String get attCorrectionInvalid => 'ກະລຸນາກວດວັນທີ, ເວລາ ແລະ ຊ່ວງກະອີກຄັ້ງ';

  @override
  String attCorrectionOutsideWindow(String from, String to) {
    return 'ເວລາຢູ່ນອກຊ່ວງກະ ($from–$to)';
  }

  @override
  String attCorrectionWindowHint(String from, String to) {
    return 'ເວລາທີ່ຮັບໄດ້: $from–$to';
  }

  @override
  String attOtClockOutBy(String time) {
    return 'ສະແກນອອກພາຍໃນ $time';
  }

  @override
  String get notificationsEmpty => 'ຍັງບໍ່ມີແຈ້ງເຕືອນ';

  @override
  String get notificationsLoadFailed => 'ບໍ່ສາມາດໂຫຼດແຈ້ງເຕືອນໄດ້.';

  @override
  String get updateRequiredTitle => 'ມີເວີຊັນໃໝ່';

  @override
  String get updateRequiredBody =>
      'ເວີຊັນນີ້ເກົ່າເກີນໄປ. ກະລຸນາອັບເດດ NEXTON ເພື່ອໃຊ້ງານຕໍ່.';

  @override
  String get updateRequiredButton => 'ອັບເດດ';

  @override
  String get updateFromAppStore => 'ກະລຸນາອັບເດດຈາກ App Store.';

  @override
  String get maintenanceTitle => 'ລະບົບກຳລັງປັບປຸງ';

  @override
  String get maintenanceDefaultBody => 'ລະບົບກຳລັງປັບປຸງ. ກະລຸນາລອງໃໝ່ພາຍຫຼັງ.';

  @override
  String get personalName => 'ຊື່';

  @override
  String get personalNameLo => 'ຊື່ (ລາວ)';

  @override
  String get personalEmployeeNumber => 'ລະຫັດພະນັກງານ';

  @override
  String get personalMobilePhone => 'ໂທລະສັບມືຖື';

  @override
  String get personalWorkPhone => 'ໂທລະສັບບ່ອນເຮັດວຽກ';

  @override
  String get personalPhoneExt => 'ເບີຕໍ່';

  @override
  String get personalHomePhone => 'ໂທລະສັບບ້ານ';

  @override
  String get personalDepartment => 'ພະແນກ';

  @override
  String get personalManager => 'ຫົວໜ້າ';

  @override
  String get personalHireDate => 'ວັນເລີ່ມງານ';

  @override
  String get personalEmergencyContacts => 'ຕິດຕໍ່ສຸກເສີນ';

  @override
  String get personalNoEmergencyContacts => 'ຍັງບໍ່ມີຂໍ້ມູນ';

  @override
  String get personalAskHrToFix => 'ຖ້າຂໍ້ມູນບໍ່ຖືກຕ້ອງ, ກະລຸນາແຈ້ງ HR.';

  @override
  String get relationshipSpouse => 'ຄູ່ສົມລົດ';

  @override
  String get relationshipParent => 'ພໍ່/ແມ່';

  @override
  String get relationshipSibling => 'ອ້າຍ/ເອື້ອຍ/ນ້ອງ';

  @override
  String get relationshipChild => 'ລູກ';

  @override
  String get relationshipFriend => 'ໝູ່';

  @override
  String get relationshipOther => 'ອື່ນໆ';

  @override
  String get profilePhotoChanged => 'ປ່ຽນຮູບໂປຣຟາຍແລ້ວ';

  @override
  String get profilePhotoNotImage => 'ໄຟລ໌ນີ້ບໍ່ແມ່ນຮູບ. ກະລຸນາເລືອກຮູບອື່ນ.';

  @override
  String get profilePhotoTooLarge => 'ຮູບໃຫຍ່ເກີນໄປ. ກະລຸນາເລືອກຮູບອື່ນ.';

  @override
  String get forgotPasswordAskHr =>
      'ກະລຸນາຕິດຕໍ່ HR ເພື່ອຕັ້ງລະຫັດຜ່ານໃໝ່ໃຫ້ທ່ານ.';

  @override
  String get notificationsMarkAllRead => 'ອ່ານທັງໝົດ';

  @override
  String notificationsUnreadCount(int count) {
    return '$count ລາຍການໃໝ່';
  }

  @override
  String get pushItemUnavailable => 'ລາຍການນີ້ບໍ່ມີແລ້ວ ຫຼື ທ່ານບໍ່ມີສິດເບິ່ງ.';

  @override
  String leaveBalanceShortIn(String year, String remaining, String requested) {
    return 'ວັນລາຂອງປີ $year ບໍ່ພຽງພໍ: ເຫຼືອ $remaining ວັນ, ຂໍ $requested ວັນ.';
  }
}
