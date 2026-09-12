/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Configuration
  static const String appName = 'Next On';
  static const String appVersion = '1.0.0';

  // API Configuration
  //
  // `https://nexton-demo.nexton.work/api` + `/v1` resolves to the `/api/v1/auth`
  // route group auth.md documents.
  //
  // The host MUST be a tenant subdomain. In production the backend resolves the
  // tenant from the leftmost label of the Host header, and `api.` / `admin.` are
  // RESERVED labels that bypass tenant resolution entirely — a login against
  // `api.nexton.work` is rejected 400 SUBDOMAIN_REQUIRED under TenantStrictMode
  // (verified live), which is why this default is a real tenant host and not the
  // reserved one. Point a different tenant build at its own subdomain without a
  // code change:
  // `--dart-define=NEXTON_API_BASE_URL=https://acme.nexton.work/api`.
  static const String baseUrl = String.fromEnvironment(
    'NEXTON_API_BASE_URL',
    defaultValue: 'https://nexton-demo.nexton.work/api',
  );
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';

  /// Dev-only tenant override on the backend (ignored in production, where the
  /// tenant is the leftmost label of the Host header). See auth.md.
  static const String tenantSlugHeader = 'X-Tenant-Slug';

  /// Mirrors the RN app's `EXPO_PUBLIC_TENANT_SLUG`; override per build with
  /// `--dart-define=NEXTON_TENANT_SLUG=<slug>`. Kept in step with the leftmost
  /// label of [baseUrl] so a dev server honouring the header resolves the same
  /// tenant the host would resolve in production.
  static const String tenantSlug = String.fromEnvironment(
    'NEXTON_TENANT_SLUG',
    defaultValue: 'nexton-demo',
  );

  // Content Types
  static const String jsonContentType = 'application/json';
  static const String formUrlEncodedContentType =
      'application/x-www-form-urlencoded';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String cachedUserKey = 'cached_user';

  /// Mirrors the login response's `must_change_password` so the requirement
  /// survives a cold start — `/auth/me` never re-reports it.
  static const String mustChangePasswordKey = 'must_change_password';
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
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String passwordRegex =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,30}$';
}
