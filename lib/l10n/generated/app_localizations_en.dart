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
  String get absent => 'Absent';

  @override
  String get lateArrival => 'Late';

  @override
  String get overtime => 'Overtime';

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
  String get monitoring => 'Monitoring';

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
