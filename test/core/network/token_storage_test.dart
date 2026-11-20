import 'dart:async';

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

  group('a sign-out\'s clear and a renewal, a sign-in or a read at the same '
      'time (#71)', () {
    late InMemorySecureStore store;
    late SecureTokenStorage storage;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      1773504662 * 1000,
      isUtc: true,
    );

    setUp(() async {
      store = InMemorySecureStore();
      storage = SecureTokenStorage(store);
      await storage.saveSignIn(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAt: expiry,
      );
    });

    Future<void> settle() => pumpEventQueue();

    test('a renewal that checks while the clear is half done writes nothing: '
        'no orphan access token stays behind', () async {
      // The clear has dropped the access token and waits on the refresh one.
      final hold = Completer<void>();
      store.holdDelete[AppConstants.refreshTokenKey] = hold;
      final clearing = storage.clear();
      await settle();

      final renewed = storage.saveRenewed(
        sentRefreshToken: 'refresh-1',
        accessToken: 'access-2',
        expiresAt: expiry,
      );
      await settle();
      hold.complete();
      await clearing;

      expect(await renewed, isFalse);
      expect(store.values, isEmpty);
      expect(await storage.readAccessToken(), isNull);
    });

    test('a renewal while the clear waits on its first step: nothing in '
        'memory either', () async {
      final hold = Completer<void>();
      store.holdDelete[AppConstants.accessTokenKey] = hold;
      final clearing = storage.clear();
      await settle();

      final renewed = storage.saveRenewed(
        sentRefreshToken: 'refresh-1',
        accessToken: 'access-2',
      );
      await settle();
      hold.complete();
      await clearing;

      expect(await renewed, isFalse);
      expect(store.values, isEmpty);
      expect(await storage.readAccessToken(), isNull);
    });

    test('a renewal after another sign-in saved its pair: false, the pair '
        'untouched, and the line is not told', () async {
      await storage.saveSignIn(
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
      );
      var told = false;

      final renewed = await storage.saveRenewed(
        sentRefreshToken: 'refresh-1',
        accessToken: 'access-2',
        onAccepted: (_) => told = true,
      );

      expect(renewed, isFalse);
      expect(told, isFalse);
      expect(await storage.readAccessToken(), 'access-b');
      expect(await storage.readRefreshToken(), 'refresh-b');
    });

    test('a renewal that is still this sign-in\'s: saved, and the line is '
        'told the token it replaces', () async {
      String? replaced;

      final renewed = await storage.saveRenewed(
        sentRefreshToken: 'refresh-1',
        accessToken: 'access-2',
        expiresAt: expiry,
        onAccepted: (previous) => replaced = previous,
      );

      expect(renewed, isTrue);
      expect(replaced, 'access-1');
      expect(await storage.readAccessToken(), 'access-2');
      expect(await storage.readRefreshToken(), 'refresh-1');
    });

    test('a refused renewal\'s clear while the next user signs in: their '
        'tokens stay', () async {
      final hold = Completer<void>();
      store.holdDelete[AppConstants.accessTokenKey] = hold;
      final clearing = storage.clearIfRefreshIs('refresh-1');
      await settle();

      final signingIn = storage.saveSignIn(
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
      );
      await settle();
      hold.complete();
      await clearing;
      await signingIn;

      expect(await storage.readAccessToken(), 'access-b');
      expect(await storage.readRefreshToken(), 'refresh-b');
      expect(store.values[AppConstants.accessTokenKey], 'access-b');
    });

    test('a first read of the access token while the clear runs: null, and '
        'nothing old kept in memory', () async {
      // A fresh start: the token is on disk, not yet in memory.
      final cold = SecureTokenStorage(store);
      final hold = Completer<void>();
      store.holdDelete[AppConstants.accessTokenKey] = hold;
      final clearing = cold.clear();
      await settle();

      final read = cold.readAccessToken();
      await settle();
      hold.complete();
      await clearing;

      expect(await read, isNull);
      expect(await cold.readAccessToken(), isNull);
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
