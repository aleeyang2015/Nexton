/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Configuration
  static const String appName = 'Next On';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';

  // Content Types
  static const String jsonContentType = 'application/json';
  static const String formUrlEncodedContentType = 'application/x-www-form-urlencoded';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userPreferencesKey = 'user_preferences';
  static const String isFirstLaunchKey = 'is_first_launch';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int firstPage = 1;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 255;

  // Cache
  static const Duration defaultCacheExpiry = Duration(hours: 1);
  static const Duration longCacheExpiry = Duration(days: 7);
  static const Duration shortCacheExpiry = Duration(minutes: 5);

  // UI Constants
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double smallBorderRadius = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Regex Patterns
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,30}$';
}