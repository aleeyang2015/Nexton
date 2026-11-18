import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/app.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/data/datasources/device_local_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/firebase_messaging_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/local_notification_data_source.dart';
import 'package:next_on/features/notifications/data/models/device_registration_model.dart';
import 'package:next_on/features/notifications/domain/entities/push_message.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/push_notifications_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/approver_access_test_doubles.dart';

/// Push set-up (#51): Firebase starting safely, and the notification
/// permission asked once, after sign-in, never again.
void main() {
  late _FakeMessaging messaging;
  late _FakeRemote remote;
  late SharedPreferences prefs;
  late _Session session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    messaging = _FakeMessaging();
    remote = _FakeRemote();
  });

  /// A launch of the App: a new container on the same phone storage.
  Future<ProviderContainer> launch({
    bool signedIn = false,
    bool pushAvailable = true,
    bool failingStore = false,
  }) async {
    session = _Session(signedIn: signedIn);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pushAvailableProvider.overrideWithValue(pushAvailable),
        firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
        localNotificationDataSourceProvider.overrideWithValue(_NoPopups()),
        deviceRemoteDataSourceProvider.overrideWithValue(remote),
        if (failingStore)
          deviceLocalDataSourceProvider.overrideWithValue(_FailingStore()),
        authSessionProvider.overrideWith(() => session),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pushNotificationsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(authSessionProvider.future);
    await pumpEventQueue();
    return container;
  }

  test('never on the login screen; once after sign-in', () async {
    await launch();
    expect(messaging.permissionAsks, 0);

    session.signIn();
    await pumpEventQueue();

    expect(messaging.permissionAsks, 1);
    expect(remote.registrations, 1);
  });

  test('a new sign-in, or a new launch, does not ask again', () async {
    await launch(signedIn: true);
    expect(messaging.permissionAsks, 1);

    session.signOut();
    await pumpEventQueue();
    session.signIn();
    await pumpEventQueue();
    expect(messaging.permissionAsks, 1);
    // The device is still registered for whoever signed in now.
    expect(remote.registrations, 2);

    await launch(signedIn: true);
    expect(messaging.permissionAsks, 1);
  });

  test('a refusal changes nothing else, and is never asked again', () async {
    messaging.allows = false;
    await launch(signedIn: true);
    expect(messaging.permissionAsks, 1);
    expect(remote.registrations, 1);

    await launch(signedIn: true);
    expect(messaging.permissionAsks, 1);
  });

  test('a source that throws does not crash: the device still registers, and '
      'the prompt is tried at the next sign-in', () async {
    messaging.throwOnPermission = true;
    await launch(signedIn: true);
    expect(messaging.permissionAsks, 1);
    expect(remote.registrations, 1);

    messaging.throwOnPermission = false;
    await launch(signedIn: true);
    expect(messaging.permissionAsks, 2);
  });

  test('a token refresh while the first prompt is open waits for it: one '
      'prompt', () async {
    final prompt = Completer<void>();
    messaging.holdPermission = prompt;
    await launch(signedIn: true);
    messaging.refresh.add('new-token');
    await pumpEventQueue();
    expect(messaging.permissionAsks, 1);

    prompt.complete();
    await pumpEventQueue();
    expect(messaging.permissionAsks, 1);
    expect(remote.registrations, 2);
  });

  test('the "already asked" flag could not be saved: the device still '
      'registers (asked again next time)', () async {
    await launch(signedIn: true, failingStore: true);
    expect(messaging.permissionAsks, 1);
    expect(remote.registrations, 1);
  });

  test(
    'Firebase did not start: no prompt, no registration, nothing touched',
    () async {
      await launch(signedIn: true, pushAvailable: false);
      expect(messaging.permissionAsks, 0);
      expect(messaging.tokenReads, 0);
      expect(remote.registrations, 0);
    },
  );

  test('Firebase failing to start never stops the App: push is off', () async {
    final ready = await AppInitializer.initialize(
      startFirebase: () async => throw Exception('no google-services'),
    );
    expect(ready, isFalse);

    final started = await AppInitializer.initialize(startFirebase: () async {});
    expect(started, isTrue);
  });
}

class _Session extends AuthSessionNotifier {
  _Session({required this.signedIn});

  final bool signedIn;

  @override
  Future<AuthSession> build() async => signedIn
      ? AuthSession.signedIn(approverTestUser())
      : const AuthSession.unauthenticated();

  void signIn() =>
      state = AsyncValue.data(AuthSession.signedIn(approverTestUser()));

  void signOut() =>
      state = const AsyncValue.data(AuthSession.unauthenticated());
}

class _FakeMessaging implements FirebaseMessagingDataSource {
  int permissionAsks = 0;
  int tokenReads = 0;
  bool allows = true;
  bool throwOnPermission = false;

  /// When set, the prompt stays open until it completes.
  Completer<void>? holdPermission;

  /// Token refreshes, as the plugin would send them.
  final refresh = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    await holdPermission?.future;
    if (throwOnPermission) throw Exception('plugin failed');
    return allows;
  }

  @override
  Future<String?> getToken() async {
    tokenReads++;
    return 'fcm-token';
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushMessage> get onMessage => const Stream.empty();
}

class _FakeRemote implements DeviceRemoteDataSource {
  int registrations = 0;

  @override
  Future<void> register(DeviceRegistrationModel body) async {
    registrations++;
  }
}

class _FailingStore implements DeviceLocalDataSource {
  @override
  String deviceId() => 'device-1';

  @override
  bool permissionAsked() => false;

  @override
  Future<void> markPermissionAsked() async => throw Exception('prefs');
}

class _NoPopups implements LocalNotificationDataSource {
  @override
  Future<void> show(PushMessage message) async {}
}
