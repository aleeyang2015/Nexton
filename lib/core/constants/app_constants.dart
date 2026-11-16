import 'package:flutter/foundation.dart';

/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Configuration
  static const String appName = 'NEXTON';
  static const String appVersion = '1.0.0';

  // API Configuration
  //
  // The base URL + `/v1` resolves to the `/api/v1/auth` route group auth.md
  // documents. Which host a build talks to:
  //
  // - `--dart-define=NEXTON_API_BASE_URL=<url>` wins in every build mode.
  // - A debug build with no define uses the test company,
  //   `nexton-demo.nexton.work`. The App talks to the live server, so a plain
  //   `flutter run` must never be able to write into a real company.
  // - A profile or release build (the store build) uses `app.nexton.work`,
  //   the mobile host: one App for every company, and the company comes from
  //   the login email.
  //
  // Never point a build at `api.nexton.work`: it is a reserved host, and a
  // login there is an admin login, not a staff one.
  static const String _definedBaseUrl = String.fromEnvironment(
    'NEXTON_API_BASE_URL',
  );
  static const String _debugBaseUrl = 'https://nexton-demo.nexton.work/api';
  static const String _releaseBaseUrl = 'https://app.nexton.work/api';

  /// The API base URL of this build. See the note above.
  static String get baseUrl =>
      resolveBaseUrl(defined: _definedBaseUrl, debug: kDebugMode);

  /// Picks the base URL: [defined] (the dart-define) when it is set, else the
  /// test company for a [debug] build, else the store host.
  @visibleForTesting
  static String resolveBaseUrl({required String defined, required bool debug}) {
    if (defined.isNotEmpty) return defined;
    return debug ? _debugBaseUrl : _releaseBaseUrl;
  }

  static const String apiVersion = 'v1';

  // Time-correction requests ("ລືມລົງເວລາ")
  /// How far back a correction may be filed, in days.
  static const int timeCorrectionMaxAgeDays = 90;

  /// Longest reason a correction request accepts.
  static const int timeCorrectionReasonMaxLength = 200;

  // Off-site scan requests ("ລົງເວລານອກພື້ນທີ່")
  /// Longest reason an off-site scan request accepts. The endpoint only asks
  /// for it to be non-empty; the cap is the app's, so the card stays readable.
  static const int offsiteReasonMaxLength = 200;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';

  /// Sent by a throttled response (429) to say how many seconds to wait
  /// before retrying — see auth-login.md §2.
  static const String retryAfterHeader = 'retry-after';

  /// Dev-only tenant override on the backend (ignored in production, where the
  /// tenant is the leftmost label of the Host header). See auth.md.
  static const String tenantSlugHeader = 'X-Tenant-Slug';

  /// Dev servers only: the live server ignores the header and takes the
  /// company from the host. Empty unless a build sets
  /// `--dart-define=NEXTON_TENANT_SLUG=<slug>`, and then it is sent as
  /// [tenantSlugHeader] on every request.
  static const String tenantSlug = String.fromEnvironment('NEXTON_TENANT_SLUG');

  // Content Types
  static const String jsonContentType = 'application/json';
  static const String formUrlEncodedContentType =
      'application/x-www-form-urlencoded';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String cachedUserKey = 'cached_user';

  /// Unix-seconds expiry of the stored access token, as `/auth/login` and
  /// `/auth/refresh` report it (auth-login.md §5). Stored beside the tokens so
  /// it is rotated and cleared with them.
  static const String expiresAtKey = 'expires_at';

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
