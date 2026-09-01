import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lo'),
  ];

  /// Application name shown as the window/task title
  ///
  /// In en, this message translates to:
  /// **'Next On'**
  String get appTitle;

  /// Login screen heading and submit button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Example@gmail.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember my email'**
  String get rememberMe;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordForcedNotice.
  ///
  /// In en, this message translates to:
  /// **'Please set a new password before continuing.'**
  String get changePasswordForcedNotice;

  /// No description provided for @changePasswordVoluntaryNotice.
  ///
  /// In en, this message translates to:
  /// **'Set a new password for your account.'**
  String get changePasswordVoluntaryNotice;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get changePasswordSuccess;

  /// No description provided for @clockInOut.
  ///
  /// In en, this message translates to:
  /// **'Clock In/Out'**
  String get clockInOut;

  /// No description provided for @attendanceHistoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistoryMenu;

  /// No description provided for @leaveMenu.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveMenu;

  /// No description provided for @leaveHistoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Leave History'**
  String get leaveHistoryMenu;

  /// No description provided for @delegateTaskMenu.
  ///
  /// In en, this message translates to:
  /// **'Delegate Task'**
  String get delegateTaskMenu;

  /// No description provided for @delegateTaskHistoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Delegation History'**
  String get delegateTaskHistoryMenu;

  /// No description provided for @salaryHistoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Salary History'**
  String get salaryHistoryMenu;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @departments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departments;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get notCheckedIn;

  /// No description provided for @checkedInStatus.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get checkedInStatus;

  /// No description provided for @clockInOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Check-in opens {time}'**
  String clockInOpensAt(String time);

  /// No description provided for @timeIn.
  ///
  /// In en, this message translates to:
  /// **'Time in'**
  String get timeIn;

  /// No description provided for @timeOut.
  ///
  /// In en, this message translates to:
  /// **'Time out'**
  String get timeOut;

  /// No description provided for @currentTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Current time'**
  String get currentTimeLabel;

  /// No description provided for @regularTimeBadge.
  ///
  /// In en, this message translates to:
  /// **'REG - Regular Time'**
  String get regularTimeBadge;

  /// Fallback only, shown by AttendanceCopy.shiftHoursLine before today's first punch — records/my has no sessions yet at that point, so there is nothing real to show.
  ///
  /// In en, this message translates to:
  /// **'Morning: 08:00 - 12:00 | Afternoon: 13:00 - 17:00'**
  String get shiftHoursPlaceholder;

  /// No description provided for @slideToClockIn.
  ///
  /// In en, this message translates to:
  /// **'Slide to check in'**
  String get slideToClockIn;

  /// No description provided for @clockMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Clock methods: {methods}'**
  String clockMethodsLabel(String methods);

  /// No description provided for @methodGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get methodGps;

  /// No description provided for @methodWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get methodWifi;

  /// No description provided for @methodBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric'**
  String get methodBiometric;

  /// No description provided for @methodField.
  ///
  /// In en, this message translates to:
  /// **'Field work'**
  String get methodField;

  /// No description provided for @slideToClockOut.
  ///
  /// In en, this message translates to:
  /// **'Slide to check out'**
  String get slideToClockOut;

  /// No description provided for @clockingIn.
  ///
  /// In en, this message translates to:
  /// **'Checking you in…'**
  String get clockingIn;

  /// No description provided for @clockingOut.
  ///
  /// In en, this message translates to:
  /// **'Checking you out…'**
  String get clockingOut;

  /// No description provided for @clockInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked in successfully'**
  String get clockInSuccess;

  /// No description provided for @clockOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked out successfully'**
  String get clockOutSuccess;

  /// No description provided for @clockInSuccessInSession.
  ///
  /// In en, this message translates to:
  /// **'Checked in for {session}'**
  String clockInSuccessInSession(String session);

  /// No description provided for @clockOutSuccessInSession.
  ///
  /// In en, this message translates to:
  /// **'Checked out of {session}'**
  String clockOutSuccessInSession(String session);

  /// No description provided for @punchLateBy.
  ///
  /// In en, this message translates to:
  /// **'You are {minutes} min late'**
  String punchLateBy(int minutes);

  /// No description provided for @punchNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Recorded, but your location could not be verified'**
  String get punchNotVerified;

  /// No description provided for @punchNotVerifiedBecause.
  ///
  /// In en, this message translates to:
  /// **'Recorded, but your location could not be verified: {reason}'**
  String punchNotVerifiedBecause(String reason);

  /// No description provided for @punchPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Recorded. The location check is still pending'**
  String get punchPendingVerification;

  /// No description provided for @rejectionOutsideGeofence.
  ///
  /// In en, this message translates to:
  /// **'you are outside the allowed area'**
  String get rejectionOutsideGeofence;

  /// No description provided for @rejectionMissingCoordinates.
  ///
  /// In en, this message translates to:
  /// **'no location was sent'**
  String get rejectionMissingCoordinates;

  /// No description provided for @rejectionUnknownWifi.
  ///
  /// In en, this message translates to:
  /// **'this WiFi network is not recognised'**
  String get rejectionUnknownWifi;

  /// No description provided for @rejectionMissingBssid.
  ///
  /// In en, this message translates to:
  /// **'no WiFi network was sent'**
  String get rejectionMissingBssid;

  /// No description provided for @ruleMockLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Fake GPS is on. Please turn it off and try again.'**
  String get ruleMockLocationDetected;

  /// No description provided for @ruleEmployeeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Your account is not linked to an employee record. Please contact HR.'**
  String get ruleEmployeeNotFound;

  /// No description provided for @ruleNoShiftAssigned.
  ///
  /// In en, this message translates to:
  /// **'No work shift has been assigned yet. Please contact HR.'**
  String get ruleNoShiftAssigned;

  /// No description provided for @ruleOutsideShiftHours.
  ///
  /// In en, this message translates to:
  /// **'Check-in has closed for today.'**
  String get ruleOutsideShiftHours;

  /// No description provided for @ruleOvernightSessionDone.
  ///
  /// In en, this message translates to:
  /// **'You have already completed the overnight shift.'**
  String get ruleOvernightSessionDone;

  /// No description provided for @ruleSessionAlreadyStarted.
  ///
  /// In en, this message translates to:
  /// **'You have already checked in. Check out instead.'**
  String get ruleSessionAlreadyStarted;

  /// No description provided for @ruleSessionAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This session already has both a check-in and a check-out.'**
  String get ruleSessionAlreadyCompleted;

  /// No description provided for @ruleSessionAlreadyCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'You have already checked out of this session.'**
  String get ruleSessionAlreadyCheckedOut;

  /// No description provided for @ruleSessionNotStarted.
  ///
  /// In en, this message translates to:
  /// **'You have not checked in for this session yet.'**
  String get ruleSessionNotStarted;

  /// No description provided for @ruleAfterCheckoutWindow.
  ///
  /// In en, this message translates to:
  /// **'The check-out window has closed.'**
  String get ruleAfterCheckoutWindow;

  /// No description provided for @ruleEarlyCheckoutRequiresReason.
  ///
  /// In en, this message translates to:
  /// **'Checking out early needs a reason.'**
  String get ruleEarlyCheckoutRequiresReason;

  /// No description provided for @earlyCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for leaving early'**
  String get earlyCheckoutTitle;

  /// No description provided for @earlyCheckoutPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are checking out early. Please tell us why.'**
  String get earlyCheckoutPrompt;

  /// No description provided for @earlyCheckoutPromptBefore.
  ///
  /// In en, this message translates to:
  /// **'Checking out before {time} needs a reason.'**
  String earlyCheckoutPromptBefore(String time);

  /// No description provided for @earlyCheckoutHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. medical appointment'**
  String get earlyCheckoutHint;

  /// No description provided for @earlyCheckoutSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get earlyCheckoutSubmit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your location is unavailable. Turn on GPS, allow location access, then try again.'**
  String get locationUnavailable;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Services are turned off. Turn them on, then try again.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Next On needs your location to check you in. Please allow location access and try again.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Open Settings, allow location for Next On, then try again.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Could not get a location fix. Move somewhere with a clearer view of the sky and try again.'**
  String get locationTimeout;

  /// No description provided for @wifiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The WiFi network could not be read. Connect to the office WiFi and try again.'**
  String get wifiUnavailable;

  /// No description provided for @fieldReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason for the field work.'**
  String get fieldReasonRequired;

  /// No description provided for @mockLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Fake GPS is on. Please turn it off and try again.'**
  String get mockLocationDetected;

  /// No description provided for @clockCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment before trying again.'**
  String get clockCooldownActive;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s attendance.'**
  String get attendanceLoadFailed;

  /// No description provided for @noTimeYet.
  ///
  /// In en, this message translates to:
  /// **'--:--'**
  String get noTimeYet;

  /// No description provided for @navList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get navList;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @workHours.
  ///
  /// In en, this message translates to:
  /// **'Work Hours'**
  String get workHours;

  /// No description provided for @leaveDays.
  ///
  /// In en, this message translates to:
  /// **'Leave Days'**
  String get leaveDays;

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get tasksDone;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @attendanceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistoryTitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @daysPresent.
  ///
  /// In en, this message translates to:
  /// **'Days present'**
  String get daysPresent;

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'Days late'**
  String get daysLate;

  /// No description provided for @daysAbsent.
  ///
  /// In en, this message translates to:
  /// **'Days absent'**
  String get daysAbsent;

  /// No description provided for @attendanceHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records this month'**
  String get attendanceHistoryEmpty;

  /// No description provided for @attendancePresentStatus.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresentStatus;

  /// No description provided for @attendanceLateStatus.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLateStatus;

  /// No description provided for @attendanceLateByMinutes.
  ///
  /// In en, this message translates to:
  /// **'Late by {minutes} min'**
  String attendanceLateByMinutes(int minutes);

  /// No description provided for @attendanceEarlyExitStatus.
  ///
  /// In en, this message translates to:
  /// **'Left early'**
  String get attendanceEarlyExitStatus;

  /// No description provided for @attendanceEarlyExitByMinutes.
  ///
  /// In en, this message translates to:
  /// **'Left {minutes} min early'**
  String attendanceEarlyExitByMinutes(int minutes);

  /// No description provided for @attendanceOvertimeHours.
  ///
  /// In en, this message translates to:
  /// **'OT {hours}h'**
  String attendanceOvertimeHours(String hours);

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursUnit;

  /// No description provided for @shiftMorningLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get shiftMorningLabel;

  /// No description provided for @shiftAfternoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get shiftAfternoonLabel;

  /// No description provided for @salaryHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salaryHistoryTitle;

  /// No description provided for @salaryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get salaryFilterAll;

  /// No description provided for @salaryFilterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get salaryFilterPaid;

  /// No description provided for @salaryFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get salaryFilterPending;

  /// No description provided for @salaryNetSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Salary'**
  String get salaryNetSalaryLabel;

  /// No description provided for @salaryPaidOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get salaryPaidOnLabel;

  /// No description provided for @salaryIncomeSection.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get salaryIncomeSection;

  /// No description provided for @salaryDeductionsSection.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get salaryDeductionsSection;

  /// No description provided for @salaryBaseSalary.
  ///
  /// In en, this message translates to:
  /// **'Base Salary'**
  String get salaryBaseSalary;

  /// No description provided for @salaryAllowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance / Others'**
  String get salaryAllowance;

  /// No description provided for @salarySocialSecurity.
  ///
  /// In en, this message translates to:
  /// **'Social Security'**
  String get salarySocialSecurity;

  /// No description provided for @salaryIncomeTax.
  ///
  /// In en, this message translates to:
  /// **'Income Tax'**
  String get salaryIncomeTax;

  /// No description provided for @salaryOtherDeductions.
  ///
  /// In en, this message translates to:
  /// **'Other Deductions'**
  String get salaryOtherDeductions;

  /// No description provided for @salaryWorkingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get salaryWorkingDaysLabel;

  /// No description provided for @salaryOvertimeLabel.
  ///
  /// In en, this message translates to:
  /// **'OT Hours'**
  String get salaryOvertimeLabel;

  /// No description provided for @salaryPaidLeaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Leave'**
  String get salaryPaidLeaveLabel;

  /// No description provided for @salaryDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download Payslip (PDF)'**
  String get salaryDownloadPdf;

  /// No description provided for @payslipDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslip'**
  String get payslipDetailTitle;

  /// No description provided for @salaryGrossLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get salaryGrossLabel;

  /// No description provided for @salaryTotalDeductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get salaryTotalDeductionsLabel;

  /// No description provided for @salaryAllowancesSection.
  ///
  /// In en, this message translates to:
  /// **'Welfare / Allowances'**
  String get salaryAllowancesSection;

  /// No description provided for @salaryAttendanceDeductionsSection.
  ///
  /// In en, this message translates to:
  /// **'Deductions — Attendance'**
  String get salaryAttendanceDeductionsSection;

  /// No description provided for @salaryStatutoryDeductionsSection.
  ///
  /// In en, this message translates to:
  /// **'Deductions — Statutory / Other'**
  String get salaryStatutoryDeductionsSection;

  /// No description provided for @salaryTaxableIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Taxable income'**
  String get salaryTaxableIncomeLabel;

  /// No description provided for @salarySocialSecurityBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Social security base'**
  String get salarySocialSecurityBaseLabel;

  /// No description provided for @salaryHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No salary records'**
  String get salaryHistoryEmpty;

  /// No description provided for @salaryHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load salary records.'**
  String get salaryHistoryLoadFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lao.
  ///
  /// In en, this message translates to:
  /// **'Lao'**
  String get lao;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String passwordTooShort(int min);

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from the current password'**
  String get newPasswordSameAsCurrent;

  /// No description provided for @confirmPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get confirmPasswordMismatch;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred. Please try again.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Please try again later.'**
  String get serverError;

  /// No description provided for @requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimeout;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled.'**
  String get requestCancelled;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get noInternetConnection;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get invalidCredentials;

  /// No description provided for @userInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive. Please contact your administrator.'**
  String get userInactive;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get currentPasswordIncorrect;

  /// No description provided for @resourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get resourceNotFound;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please log in again.'**
  String get unauthorized;

  /// No description provided for @accessForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden. You don\'t have permission.'**
  String get accessForbidden;

  /// No description provided for @badRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad request. Please check your input.'**
  String get badRequest;

  /// No description provided for @pageNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFoundTitle;

  /// No description provided for @pageNotFoundHeading.
  ///
  /// In en, this message translates to:
  /// **'404 - Page Not Found'**
  String get pageNotFoundHeading;

  /// No description provided for @pageNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get pageNotFoundMessage;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @errorDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorDetailsLabel(String details);

  /// No description provided for @timeOffHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'Leave History'**
  String get timeOffHistoryTab;

  /// No description provided for @timeOffRequestTab.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get timeOffRequestTab;

  /// No description provided for @leaveFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get leaveFilterAll;

  /// No description provided for @leaveCategorySick.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get leaveCategorySick;

  /// No description provided for @leaveCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Leave'**
  String get leaveCategoryPersonal;

  /// No description provided for @leaveCategoryAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave'**
  String get leaveCategoryAnnual;

  /// No description provided for @leaveCategoryRest.
  ///
  /// In en, this message translates to:
  /// **'Rest Leave'**
  String get leaveCategoryRest;

  /// No description provided for @leaveDateFrom.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get leaveDateFrom;

  /// No description provided for @leaveDateTo.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get leaveDateTo;

  /// No description provided for @daysCountUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysCountUnit;

  /// No description provided for @leaveStatusPending.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get leaveStatusPending;

  /// No description provided for @leaveStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get leaveStatusApproved;

  /// No description provided for @leaveStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get leaveStatusRejected;

  /// No description provided for @leaveStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get leaveStepSubmitted;

  /// No description provided for @leaveStepManagerReview.
  ///
  /// In en, this message translates to:
  /// **'Manager review'**
  String get leaveStepManagerReview;

  /// No description provided for @leaveStepManagerWaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting manager review'**
  String get leaveStepManagerWaiting;

  /// No description provided for @leaveStepHrApproval.
  ///
  /// In en, this message translates to:
  /// **'HR approval'**
  String get leaveStepHrApproval;

  /// No description provided for @leaveReviewerCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get leaveReviewerCommentLabel;

  /// No description provided for @leaveHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your leave history.'**
  String get leaveHistoryLoadFailed;

  /// No description provided for @leaveHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leave requests found'**
  String get leaveHistoryEmpty;

  /// No description provided for @leaveDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String leaveDaysSuffix(int days);

  /// No description provided for @leaveTotalDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{days} days total'**
  String leaveTotalDaysSuffix(int days);

  /// No description provided for @leaveRequestCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave type'**
  String get leaveRequestCategoryLabel;

  /// No description provided for @leaveRequestReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get leaveRequestReasonLabel;

  /// No description provided for @leaveRequestReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the reason for your leave'**
  String get leaveRequestReasonHint;

  /// No description provided for @leaveRequestSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get leaveRequestSubmit;

  /// No description provided for @leaveRequestSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Leave request submitted'**
  String get leaveRequestSubmitSuccess;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @leaveBalanceRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave days remaining'**
  String get leaveBalanceRemainingLabel;

  /// No description provided for @leaveBalanceUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used {days} days'**
  String leaveBalanceUsedLabel(int days);

  /// No description provided for @leaveYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String leaveYearLabel(int year);

  /// No description provided for @leaveSelectDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Select leave dates'**
  String get leaveSelectDatesLabel;

  /// No description provided for @leaveDatesTotalPrefix.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get leaveDatesTotalPrefix;

  /// No description provided for @leaveNoDatesSelected.
  ///
  /// In en, this message translates to:
  /// **'No dates selected yet'**
  String get leaveNoDatesSelected;

  /// No description provided for @leaveReturnToWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Return-to-work date'**
  String get leaveReturnToWorkLabel;

  /// No description provided for @leaveSelectButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get leaveSelectButtonLabel;

  /// No description provided for @leaveAttachFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get leaveAttachFileLabel;

  /// No description provided for @leaveOptionalBadge.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get leaveOptionalBadge;

  /// No description provided for @leaveChooseFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get leaveChooseFileButton;

  /// No description provided for @timeOffApprovalsTab.
  ///
  /// In en, this message translates to:
  /// **'Team Approvals'**
  String get timeOffApprovalsTab;

  /// No description provided for @leaveApprovalsPendingHeader.
  ///
  /// In en, this message translates to:
  /// **'Needs your approval ({count})'**
  String leaveApprovalsPendingHeader(int count);

  /// No description provided for @leaveApprovalsHistoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Approval history'**
  String get leaveApprovalsHistoryHeader;

  /// No description provided for @leaveApprovalNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get leaveApprovalNewBadge;

  /// No description provided for @leaveApprovalApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get leaveApprovalApproveAction;

  /// No description provided for @leaveApprovalRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get leaveApprovalRejectAction;

  /// No description provided for @leaveApprovalsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the approval data.'**
  String get leaveApprovalsLoadFailed;

  /// No description provided for @leaveApprovalsPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your approval'**
  String get leaveApprovalsPendingEmpty;

  /// No description provided for @leaveApprovalsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No approval history yet'**
  String get leaveApprovalsHistoryEmpty;

  /// No description provided for @leaveApprovalDecideFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t go through. Please try again.'**
  String get leaveApprovalDecideFailed;

  /// No description provided for @leaveTypeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load leave types.'**
  String get leaveTypeLoadFailed;

  /// No description provided for @leaveStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get leaveStatusCancelled;

  /// No description provided for @leaveStepDeptHead.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get leaveStepDeptHead;

  /// No description provided for @leaveStepHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get leaveStepHr;

  /// No description provided for @leaveDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Day part'**
  String get leaveDurationLabel;

  /// No description provided for @leaveDurationFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get leaveDurationFullDay;

  /// No description provided for @leaveDurationFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get leaveDurationFirstHalf;

  /// No description provided for @leaveDurationSecondHalf.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get leaveDurationSecondHalf;

  /// No description provided for @leaveHalfDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Half day (0.5)'**
  String get leaveHalfDayLabel;

  /// No description provided for @leaveRequiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get leaveRequiredBadge;

  /// No description provided for @leaveRequiresAttachmentBlocked.
  ///
  /// In en, this message translates to:
  /// **'This leave type needs a supporting document. Attaching files isn\'t available in the app yet — please submit this request on the web.'**
  String get leaveRequiresAttachmentBlocked;

  /// No description provided for @leaveInsufficientBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Not enough leave balance for the days selected.'**
  String get leaveInsufficientBalanceHint;

  /// No description provided for @leaveReturnDateHint.
  ///
  /// In en, this message translates to:
  /// **'The return-to-work date must be after your last leave day.'**
  String get leaveReturnDateHint;

  /// No description provided for @leaveMaxDaysHint.
  ///
  /// In en, this message translates to:
  /// **'This leave type allows at most {days} days per request.'**
  String leaveMaxDaysHint(int days);

  /// No description provided for @leaveEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit request'**
  String get leaveEditAction;

  /// No description provided for @leaveCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get leaveCancelAction;

  /// No description provided for @leaveCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this leave request? The reserved days go back to your balance.'**
  String get leaveCancelConfirm;

  /// No description provided for @leaveRequestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Leave request updated'**
  String get leaveRequestUpdated;

  /// No description provided for @leaveRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Leave request cancelled'**
  String get leaveRequestCancelled;

  /// No description provided for @leaveRequestCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel the request.'**
  String get leaveRequestCancelFailed;

  /// No description provided for @leaveRejectReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get leaveRejectReasonTitle;

  /// No description provided for @leaveRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Let the employee know why'**
  String get leaveRejectReasonHint;

  /// No description provided for @leaveRejectReasonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get leaveRejectReasonSubmit;

  /// No description provided for @leaveStepRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Someone else just acted on this request — please review it again.'**
  String get leaveStepRefreshed;

  /// No description provided for @leaveDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave details'**
  String get leaveDetailTitle;

  /// No description provided for @leaveApprovalChainLabel.
  ///
  /// In en, this message translates to:
  /// **'Approval progress'**
  String get leaveApprovalChainLabel;

  /// No description provided for @leaveApproverNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get leaveApproverNoteLabel;

  /// No description provided for @leaveAttachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get leaveAttachmentsLabel;

  /// No description provided for @leavePendingRequestExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a leave request awaiting approval. Wait for it to be resolved first.'**
  String get leavePendingRequestExists;

  /// No description provided for @leaveOverlapping.
  ///
  /// In en, this message translates to:
  /// **'Those dates overlap with another leave request.'**
  String get leaveOverlapping;

  /// No description provided for @leaveInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough leave balance for those dates.'**
  String get leaveInsufficientBalance;

  /// No description provided for @leaveStepChanged.
  ///
  /// In en, this message translates to:
  /// **'This request was just updated — please review it again.'**
  String get leaveStepChanged;

  /// No description provided for @leaveNotApprover.
  ///
  /// In en, this message translates to:
  /// **'You can\'t approve this step.'**
  String get leaveNotApprover;

  /// No description provided for @leaveInvalidStatus.
  ///
  /// In en, this message translates to:
  /// **'This request can no longer be changed.'**
  String get leaveInvalidStatus;

  /// No description provided for @leaveEmployeeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t linked to an employee record.'**
  String get leaveEmployeeNotFound;

  /// No description provided for @leaveTypePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select leave type'**
  String get leaveTypePickerTitle;

  /// No description provided for @leaveTypeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get leaveTypeSearchHint;

  /// No description provided for @leaveTypeSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching leave types'**
  String get leaveTypeSearchEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lo':
      return AppLocalizationsLo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
