import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/app.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/push_notifications_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/push_test_doubles.dart';

/// Push set-up (#51): Firebase starting safely, and the notification
/// permission asked once, after sign-in, never again.
void main() {
  late FakeMessaging messaging;
  late FakeDeviceRemote remote;
  late SharedPreferences prefs;
  late FakePushSession session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    messaging = FakeMessaging();
    remote = FakeDeviceRemote();
  });

  /// A launch of the App: a new container on the same phone storage.
  Future<ProviderContainer> launch({
    bool signedIn = false,
    bool pushAvailable = true,
    bool failingStore = false,
  }) async {
    session = FakePushSession(signedIn: signedIn);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pushAvailableProvider.overrideWithValue(pushAvailable),
        firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
        localNotificationDataSourceProvider.overrideWithValue(NoPopups()),
        deviceRemoteDataSourceProvider.overrideWithValue(remote),
        if (failingStore)
          deviceLocalDataSourceProvider.overrideWithValue(FailingDeviceStore()),
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
    // The refresh sent the new token (#52: a PUT, not a second POST).
    expect(remote.registrations, 1);
    expect(remote.updated, hasLength(1));
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
