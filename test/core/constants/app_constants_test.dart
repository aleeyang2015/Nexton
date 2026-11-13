import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';

void main() {
  group('AppConstants.baseUrl', () {
    test('a debug run with no define talks to the test company', () {
      // `flutter test` runs in debug mode with no dart-defines.
      expect(AppConstants.baseUrl, 'https://nexton-demo.nexton.work/api');
    });
  });

  group('AppConstants.resolveBaseUrl', () {
    test('the NEXTON_API_BASE_URL define wins in any build', () {
      const defined = 'https://acme.nexton.work/api';

      expect(
        AppConstants.resolveBaseUrl(defined: defined, debug: true),
        defined,
      );
      expect(
        AppConstants.resolveBaseUrl(defined: defined, debug: false),
        defined,
      );
    });

    test('a debug build with no define uses nexton-demo', () {
      expect(
        AppConstants.resolveBaseUrl(defined: '', debug: true),
        'https://nexton-demo.nexton.work/api',
      );
    });

    test('a profile or release build with no define uses app.nexton.work', () {
      expect(
        AppConstants.resolveBaseUrl(defined: '', debug: false),
        'https://app.nexton.work/api',
      );
    });
  });

  test('no tenant slug is defined by default', () {
    expect(AppConstants.tenantSlug, isEmpty);
  });
}
