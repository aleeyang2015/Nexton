// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Next On';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Example@gmail.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get rememberMe => 'Remember my email';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordForcedNotice =>
      'Please set a new password before continuing.';

  @override
  String get changePasswordVoluntaryNotice =>
      'Set a new password for your account.';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordHint => 'Enter your current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordHint => 'At least 8 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordHint => 'Re-enter your new password';

  @override
  String get savePassword => 'Save Password';

  @override
  String get logout => 'Sign Out';

  @override
  String get changePasswordSuccess => 'Password changed successfully';

  @override
  String get clockInOut => 'Clock In/Out';

  @override
  String get activities => 'Activities';

  @override
  String get documents => 'Documents';

  @override
  String get reports => 'Reports';

  @override
  String get departments => 'Departments';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get notCheckedIn => 'Not checked in';

  @override
  String get checkedInStatus => 'Checked in';

  @override
  String clockInOpensAt(String time) {
    return 'Check-in opens $time';
  }

  @override
  String get timeIn => 'Time in';

  @override
  String get timeOut => 'Time out';

  @override
  String get currentTimeLabel => 'Current time';

  @override
  String get regularTimeBadge => 'REG - Regular Time';

  @override
  String get shiftHoursPlaceholder =>
      'Morning: 08:00 - 12:00 | Afternoon: 13:00 - 17:00';

  @override
  String get slideToClockIn => 'Slide to check in';

  @override
  String clockMethodsLabel(String methods) {
    return 'Clock methods: $methods';
  }

  @override
  String get methodGps => 'GPS';

  @override
  String get methodWifi => 'WiFi';

  @override
  String get methodBiometric => 'Biometric';

  @override
  String get methodField => 'Field work';

  @override
  String get slideToClockOut => 'Slide to check out';

  @override
  String get clockingIn => 'Checking you in…';

  @override
  String get clockingOut => 'Checking you out…';

  @override
  String get clockInSuccess => 'Checked in successfully';

  @override
  String get clockOutSuccess => 'Checked out successfully';

  @override
  String clockInSuccessInSession(String session) {
    return 'Checked in for $session';
  }

  @override
  String clockOutSuccessInSession(String session) {
    return 'Checked out of $session';
  }

  @override
  String punchLateBy(int minutes) {
    return 'You are $minutes min late';
  }

  @override
  String get punchNotVerified =>
      'Recorded, but your location could not be verified';

  @override
  String punchNotVerifiedBecause(String reason) {
    return 'Recorded, but your location could not be verified: $reason';
  }

  @override
  String get punchPendingVerification =>
      'Recorded. The location check is still pending';

  @override
  String get rejectionOutsideGeofence => 'you are outside the allowed area';

  @override
  String get rejectionMissingCoordinates => 'no location was sent';

  @override
  String get rejectionUnknownWifi => 'this WiFi network is not recognised';

  @override
  String get rejectionMissingBssid => 'no WiFi network was sent';

  @override
  String get ruleMockLocationDetected =>
      'Fake GPS is on. Please turn it off and try again.';

  @override
  String get ruleEmployeeNotFound =>
      'Your account is not linked to an employee record. Please contact HR.';

  @override
  String get ruleNoShiftAssigned =>
      'No work shift has been assigned yet. Please contact HR.';

  @override
  String get ruleOutsideShiftHours => 'Check-in has closed for today.';

  @override
  String get ruleOvernightSessionDone =>
      'You have already completed the overnight shift.';

  @override
  String get ruleSessionAlreadyStarted =>
      'You have already checked in. Check out instead.';

  @override
  String get ruleSessionAlreadyCompleted =>
      'This session already has both a check-in and a check-out.';

  @override
  String get ruleSessionAlreadyCheckedOut =>
      'You have already checked out of this session.';

  @override
  String get ruleSessionNotStarted =>
      'You have not checked in for this session yet.';

  @override
  String get ruleAfterCheckoutWindow => 'The check-out window has closed.';

  @override
  String get ruleEarlyCheckoutRequiresReason =>
      'Checking out early needs a reason.';

  @override
  String get earlyCheckoutTitle => 'Reason for leaving early';

  @override
  String get earlyCheckoutPrompt =>
      'You are checking out early. Please tell us why.';

  @override
  String earlyCheckoutPromptBefore(String time) {
    return 'Checking out before $time needs a reason.';
  }

  @override
  String get earlyCheckoutHint => 'e.g. medical appointment';

  @override
  String get earlyCheckoutSubmit => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get locationUnavailable =>
      'Your location is unavailable. Turn on GPS, allow location access, then try again.';

  @override
  String get locationServiceDisabled =>
      'Location Services are turned off. Turn them on, then try again.';

  @override
  String get locationPermissionDenied =>
      'Next On needs your location to check you in. Please allow location access and try again.';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is blocked. Open Settings, allow location for Next On, then try again.';

  @override
  String get locationTimeout =>
      'Could not get a location fix. Move somewhere with a clearer view of the sky and try again.';

  @override
  String get wifiUnavailable =>
      'The WiFi network could not be read. Connect to the office WiFi and try again.';

  @override
  String get fieldReasonRequired => 'Please give a reason for the field work.';

  @override
  String get mockLocationDetected =>
      'Fake GPS is on. Please turn it off and try again.';

  @override
  String get clockCooldownActive =>
      'Too many attempts. Please wait a moment before trying again.';

  @override
  String get attendanceLoadFailed => 'Could not load today\'s attendance.';

  @override
  String get noTimeYet => '--:--';

  @override
  String get navList => 'List';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get workHours => 'Work Hours';

  @override
  String get leaveDays => 'Leave Days';

  @override
  String get tasksDone => 'Tasks Done';

  @override
  String get personal => 'Personal';

  @override
  String get help => 'Help';

  @override
  String get attendanceHistoryTitle => 'Attendance History';

  @override
  String get viewAll => 'View all';

  @override
  String get daysPresent => 'Days present';

  @override
  String get daysLate => 'Days late';

  @override
  String get daysAbsent => 'Days absent';

  @override
  String get language => 'Language';

  @override
  String get lao => 'Lao';

  @override
  String get english => 'English';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email format';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String passwordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get currentPasswordRequired => 'Please enter your current password';

  @override
  String get newPasswordSameAsCurrent =>
      'New password must be different from the current password';

  @override
  String get confirmPasswordMismatch => 'Passwords do not match';

  @override
  String get networkError => 'Network error occurred. Please try again.';

  @override
  String get serverError =>
      'Something went wrong on our end. Please try again later.';

  @override
  String get requestTimeout => 'Request timed out. Please try again.';

  @override
  String get requestCancelled => 'Request was cancelled.';

  @override
  String get noInternetConnection => 'No internet connection.';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get userInactive =>
      'Your account is inactive. Please contact your administrator.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect.';

  @override
  String get resourceNotFound => 'The requested resource was not found.';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get unauthorized => 'Unauthorized. Please log in again.';

  @override
  String get accessForbidden => 'Access forbidden. You don\'t have permission.';

  @override
  String get badRequest => 'Bad request. Please check your input.';

  @override
  String get pageNotFoundTitle => 'Page Not Found';

  @override
  String get pageNotFoundHeading => '404 - Page Not Found';

  @override
  String get pageNotFoundMessage =>
      'The page you are looking for does not exist.';

  @override
  String get goHome => 'Go Home';

  @override
  String errorDetailsLabel(String details) {
    return 'Error: $details';
  }
}
