import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/network/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureTokenStorage', () {
    late InMemorySecureStore store;
    late SecureTokenStorage storage;

    setUp(() {
      store = InMemorySecureStore();
      storage = SecureTokenStorage(store);
    });

    test('round-trips both tokens through the secure store', () async {
      await storage.writeAccessToken('access-1');
      await storage.writeRefreshToken('refresh-1');

      expect(await storage.readAccessToken(), 'access-1');
      expect(await storage.readRefreshToken(), 'refresh-1');
      expect(store.values[AppConstants.accessTokenKey], 'access-1');
      expect(store.values[AppConstants.refreshTokenKey], 'refresh-1');
    });

    test('reads an access token written by an earlier session', () async {
      store.values[AppConstants.accessTokenKey] = 'from-disk';

      expect(await SecureTokenStorage(store).readAccessToken(), 'from-disk');
    });

    test('clear drops both tokens and the in-memory mirror', () async {
      await storage.writeAccessToken('access-1');
      await storage.writeRefreshToken('refresh-1');

      await storage.clear();

      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(store.values, isEmpty);
    });

    test('round-trips the access-token expiry as Unix seconds', () async {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        1773504662 * 1000,
        isUtc: true,
      );

      await storage.writeAccessTokenExpiry(expiry);

      expect(await storage.readAccessTokenExpiry(), expiry);
      // Stored in the same Unix-seconds form the wire uses, not a Dart string.
      expect(store.values[AppConstants.expiresAtKey], '1773504662');
    });

    test('reads an expiry written by an earlier session', () async {
      store.values[AppConstants.expiresAtKey] = '1773504662';

      expect(
        await SecureTokenStorage(store).readAccessTokenExpiry(),
        DateTime.fromMillisecondsSinceEpoch(1773504662 * 1000, isUtc: true),
      );
    });

    test('a null expiry drops the stored one', () async {
      await storage.writeAccessTokenExpiry(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      await storage.writeAccessTokenExpiry(null);

      expect(await storage.readAccessTokenExpiry(), isNull);
      expect(store.values.containsKey(AppConstants.expiresAtKey), isFalse);
    });

    test('an unusable stored expiry reads as unknown', () async {
      store.values[AppConstants.expiresAtKey] = 'not-a-timestamp';

      expect(await SecureTokenStorage(store).readAccessTokenExpiry(), isNull);
    });

    test('clear drops the expiry with the tokens', () async {
      await storage.writeAccessToken('access-1');
      await storage.writeRefreshToken('refresh-1');
      await storage.writeAccessTokenExpiry(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      await storage.clear();

      // An expiry must never outlive the token it described.
      expect(await storage.readAccessTokenExpiry(), isNull);
      expect(store.values, isEmpty);
    });
  });

  group('tokenExpiryFromUnixSeconds', () {
    test('reads the int and numeric-string forms', () {
      final expected = DateTime.fromMillisecondsSinceEpoch(
        1773504662 * 1000,
        isUtc: true,
      );

      expect(tokenExpiryFromUnixSeconds(1773504662), expected);
      expect(tokenExpiryFromUnixSeconds('1773504662'), expected);
      expect(tokenExpiryFromUnixSeconds(1773504662.0), expected);
    });

    test('reads a missing or unusable value as unknown', () {
      for (final value in [null, 0, -1, '', 'later', <String>[]]) {
        expect(tokenExpiryFromUnixSeconds(value), isNull, reason: '\$value');
      }
    });
  });

  group('LegacySessionMigration', () {
    test('moves a SharedPreferences session into the keychain', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.accessTokenKey: 'access-1',
        AppConstants.refreshTokenKey: 'refresh-1',
        AppConstants.cachedUserKey: '{"id":"u1"}',
        AppConstants.mustChangePasswordKey: 'true',
        'unrelated_setting': 'keep me',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = InMemorySecureStore();

      await LegacySessionMigration(prefs: prefs, secureStore: store).run();

      expect(store.values[AppConstants.accessTokenKey], 'access-1');
      expect(store.values[AppConstants.refreshTokenKey], 'refresh-1');
      expect(store.values[AppConstants.cachedUserKey], '{"id":"u1"}');
      expect(store.values[AppConstants.mustChangePasswordKey], 'true');

      // Nothing auth-related may survive in plain storage.
      expect(prefs.getString(AppConstants.accessTokenKey), isNull);
      expect(prefs.getString(AppConstants.refreshTokenKey), isNull);
      expect(prefs.getString(AppConstants.cachedUserKey), isNull);
      expect(prefs.getString(AppConstants.mustChangePasswordKey), isNull);
      expect(prefs.getString('unrelated_setting'), 'keep me');
    });

    test('renames the pre-rename auth_token key', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'legacy-access'});
      final prefs = await SharedPreferences.getInstance();
      final store = InMemorySecureStore();

      await LegacySessionMigration(prefs: prefs, secureStore: store).run();

      expect(store.values[AppConstants.accessTokenKey], 'legacy-access');
      expect(prefs.getString('auth_token'), isNull);
    });

    test('never clobbers a session already in the keychain', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.accessTokenKey: 'stale',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = InMemorySecureStore({
        AppConstants.accessTokenKey: 'current',
      });

      await LegacySessionMigration(prefs: prefs, secureStore: store).run();

      expect(store.values[AppConstants.accessTokenKey], 'current');
      expect(prefs.getString(AppConstants.accessTokenKey), isNull);
    });

    test('is a no-op on a clean install', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = InMemorySecureStore();

      await LegacySessionMigration(prefs: prefs, secureStore: store).run();

      expect(store.values, isEmpty);
    });
  });
}
