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
