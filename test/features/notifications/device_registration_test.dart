import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/locale_provider.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:next_on/features/notifications/data/models/device_registration_model.dart';
import 'package:next_on/features/notifications/domain/repositories/push_notification_repository.dart';
import 'package:next_on/features/notifications/domain/usecases/sign_out_this_device_usecase.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/push_notifications_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/push_test_doubles.dart';

/// The backend's copy of this phone (#52): the body, a new token, the
/// language, the sign-off, and every failure kept silent.
void main() {
  group('the body', () {
    DeviceRegistrationModel body({
      bool isIOS = false,
      String os = 'Android 14 (API 34)',
      String app = '1.0.0',
      String language = 'lo',
    }) => DeviceRegistrationModel.forPhone(
      deviceId: 'dev-1',
      deviceToken: 'tok',
      isIOS: isIOS,
      rawOsVersion: os,
      appVersion: app,
      languageCode: language,
    );

    test('every field, none empty, each fits its column', () {
      for (final b in [
        body(),
        body(isIOS: true, os: 'Version 17.5 (Build 21F79)'),
        body(os: '   '),
        body(app: ''),
        body(os: 'x' * 80, app: '1.0.0+999999999999999999'),
      ]) {
        final json = b.toJson();
        for (final key in [
          'device_id',
          'device_type',
          'device_token',
          'device_name',
          'app_version',
          'os_version',
          'locale',
        ]) {
          expect(json[key], isA<String>(), reason: key);
          expect((json[key] as String).trim(), isNotEmpty, reason: key);
        }
        expect((json['os_version'] as String).length, lessThanOrEqualTo(20));
        expect((json['app_version'] as String).length, lessThanOrEqualTo(20));
        expect((json['device_name'] as String).length, lessThanOrEqualTo(255));
      }
    });

    test('the phone\'s kind and name', () {
      expect(body().toJson()['device_type'], 'android');
      expect(body().toJson()['device_name'], 'Android phone');
      expect(body(isIOS: true).toJson()['device_type'], 'ios');
      expect(body(isIOS: true).toJson()['device_name'], 'iPhone');
    });

    test('locale is the App\'s language, lo or en', () {
      expect(body(language: 'lo').toJson()['locale'], 'lo');
      expect(body(language: 'en').toJson()['locale'], 'en');
      expect(body(language: 'fr').toJson()['locale'], 'lo');
    });
  });

  group('the calls', () {
    late _StubAdapter adapter;
    late DeviceRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      source = DeviceRemoteDataSourceImpl(
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
      );
    });

    test('PUT the new token; 404 (no active row) says so', () async {
      expect(await source.updateToken('dev 1', 'tok'), isTrue);
      expect(adapter.last!.method, 'PUT');
      expect(adapter.last!.path, endsWith('/mobile/devices/dev%201'));
      expect(jsonDecode(adapter.lastBody!), {'device_token': 'tok'});

      adapter.status = 404;
      expect(await source.updateToken('dev-1', 'tok'), isFalse);
    });

    test('DELETE the row; 404 (already off) counts as done', () async {
      await source.unregister('dev-1');
      expect(adapter.last!.method, 'DELETE');

      adapter.status = 404;
      await source.unregister('dev-1');
    });

    test(
      'another failure is not swallowed here (the repository does)',
      () async {
        adapter.status = 500;
        await expectLater(
          source.unregister('dev-1'),
          throwsA(isA<DioException>()),
        );
      },
    );
  });

  group('while signed in', () {
    late FakeMessaging messaging;
    late FakeDeviceRemote remote;
    late FakePushSession session;
    late ProviderContainer container;

    Future<void> launch() async {
      SharedPreferences.setMockInitialValues({'push_permission_asked': true});
      final prefs = await SharedPreferences.getInstance();
      messaging = FakeMessaging();
      remote = FakeDeviceRemote();
      session = FakePushSession(signedIn: true);
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pushAvailableProvider.overrideWithValue(true),
          firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
          localNotificationDataSourceProvider.overrideWithValue(NoPopups()),
          deviceRemoteDataSourceProvider.overrideWithValue(remote),
          authSessionProvider.overrideWith(() => session),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(pushNotificationsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(authSessionProvider.future);
      await pumpEventQueue();
    }

    test('registers with the App\'s language; a language change registers '
        'again in the new one', () async {
      await launch();
      expect(remote.registered.single.locale, 'lo');

      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('en'));
      await pumpEventQueue();

      expect(remote.registered, hasLength(2));
      expect(remote.registered.last.locale, 'en');
    });

    test(
      'a new token is PUT; no row on the server (404): POST instead',
      () async {
        await launch();
        messaging.refresh.add('new');
        await pumpEventQueue();
        expect(remote.updated, hasLength(1));
        expect(remote.registered, hasLength(1));

        remote.updateFindsRow = false;
        messaging.refresh.add('newer');
        await pumpEventQueue();
        expect(remote.updated, hasLength(2));
        expect(remote.registered, hasLength(2));
      },
    );

    for (final (label, error) in <(String, Object)>[
      ('429', _status(429)),
      ('500', _status(500)),
      ('a timeout', TimeoutException('slow')),
    ]) {
      test(
        '$label on register is swallowed: no throw, nothing shown',
        () async {
          SharedPreferences.setMockInitialValues({
            'push_permission_asked': true,
          });
          final prefs = await SharedPreferences.getInstance();
          messaging = FakeMessaging();
          remote = FakeDeviceRemote()..registerError = error;
          session = FakePushSession(signedIn: true);
          container = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              pushAvailableProvider.overrideWithValue(true),
              firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
              localNotificationDataSourceProvider.overrideWithValue(NoPopups()),
              deviceRemoteDataSourceProvider.overrideWithValue(remote),
              authSessionProvider.overrideWith(() => session),
            ],
          );
          addTearDown(container.dispose);
          final sub = container.listen(pushNotificationsProvider, (_, _) {});
          addTearDown(sub.close);
          await container.read(authSessionProvider.future);
          await pumpEventQueue();

          expect(remote.registrations, 1);
          expect(container.read(pushNotificationsProvider), isFalse);
        },
      );
    }
  });

  group('signing this phone off', () {
    test('DELETE first, then the FCM token', () async {
      final repo = _RecordingRepository();
      await SignOutThisDeviceUseCase(repo)(tokensLive: true);
      await pumpEventQueue();
      expect(repo.calls, ['unregister', 'deleteToken']);
    });

    test(
      'a DELETE that hangs past the limit does not hold the sign-out',
      () async {
        final repo = _RecordingRepository()..hang = Completer<void>();
        await SignOutThisDeviceUseCase(
          repo,
          deleteLimit: const Duration(milliseconds: 20),
        )(tokensLive: true);
        await pumpEventQueue();
        expect(repo.calls, ['unregister', 'deleteToken']);
      },
    );

    test('a failed DELETE still kills the token; never throws', () async {
      final repo = _RecordingRepository()..unregisterFails = true;
      await SignOutThisDeviceUseCase(repo)(tokensLive: true);
      await pumpEventQueue();
      expect(repo.calls, ['unregister', 'deleteToken']);
    });

    test('a forced sign-out (tokens gone): the FCM token only', () async {
      final repo = _RecordingRepository();
      await SignOutThisDeviceUseCase(repo)(tokensLive: false);
      await pumpEventQueue();
      expect(repo.calls, ['deleteToken']);
    });

    test('Firebase never started: nothing at all', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(signOutThisDeviceProvider)(tokensLive: true);
    });
  });
  group('races at sign-out (#52 reviews)', () {
    late FakeMessaging messaging;
    late FakeDeviceRemote remote;
    late FakePushSession session;
    late ProviderContainer container;

    Future<void> launch() async {
      SharedPreferences.setMockInitialValues({'push_permission_asked': true});
      final prefs = await SharedPreferences.getInstance();
      messaging = FakeMessaging();
      remote = FakeDeviceRemote();
      session = FakePushSession(signedIn: true);
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pushAvailableProvider.overrideWithValue(true),
          firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
          localNotificationDataSourceProvider.overrideWithValue(NoPopups()),
          deviceRemoteDataSourceProvider.overrideWithValue(remote),
          authSessionProvider.overrideWith(() => session),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(pushNotificationsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(authSessionProvider.future);
      await pumpEventQueue();
    }

    test(
      'a registration on its way lands before the DELETE, never after',
      () async {
        await launch();
        final hold = Completer<void>();
        remote.holdRegister = hold;
        final order = <String>[];
        remote.onRegister = () => order.add('POST');
        remote.onUnregister = () => order.add('DELETE');
        // A language change starts a registration that is still on its way.
        await container
            .read(localeProvider.notifier)
            .setLocale(const Locale('en'));
        await pumpEventQueue();

        final signOff = container.read(signOutThisDeviceProvider)(
          tokensLive: true,
        );
        await pumpEventQueue();
        // The POST has not landed yet, and no DELETE has gone out.
        expect(order, isEmpty);
        hold.complete();
        await signOff;

        expect(order, ['POST', 'DELETE']);
      },
    );

    test('a token delete that failed offline is tried again before the next '
        'registration reads a token', () async {
      await launch();
      messaging.deleteFails = true;
      await container.read(signOutThisDeviceProvider)(tokensLive: true);
      await pumpEventQueue();
      expect(messaging.tokenDeletes, 1);

      messaging.deleteFails = false;
      session.signOut();
      await pumpEventQueue();
      session.signIn();
      await pumpEventQueue();

      expect(messaging.tokenDeletes, 2);
      expect(remote.registrations, greaterThanOrEqualTo(2));
    });
  });
}

DioException _status(int code) {
  final options = RequestOptions(path: '/mobile/devices');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
    type: DioExceptionType.badResponse,
  );
}

class _RecordingRepository implements PushNotificationRepository {
  final List<String> calls = [];
  Completer<void>? hang;
  bool unregisterFails = false;

  @override
  FutureResult<Unit> unregisterDevice() async {
    calls.add('unregister');
    await hang?.future;
    return unregisterFails
        ? const Result.failure(Failure.network(message: 'offline'))
        : const Result.success(Unit.instance);
  }

  @override
  FutureResult<Unit> deleteToken() async {
    calls.add('deleteToken');
    return const Result.success(Unit.instance);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  RequestOptions? last;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    lastBody = options.data == null ? null : jsonEncode(options.data);
    return ResponseBody.fromString(
      jsonEncode({'success': status < 400}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
