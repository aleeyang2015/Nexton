import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/domain/entities/push_message.dart';
import 'package:next_on/features/notifications/domain/push_route.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/push_open_notifier.dart';
import 'package:next_on/features/notifications/presentation/push_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/push_test_doubles.dart';

/// A tapped push opens its item (#53): once, only with a full session, and
/// never for the next user on the phone.
void main() {
  const leave = {
    'notification_type': 'leave_request',
    'reference_type': 'leave_request',
    'reference_id': 'lr-1',
  };
  const ot = {
    'notification_type': 'overtime_request',
    'reference_type': 'overtime_request',
    'reference_id': 'ot-9',
  };

  late FakeMessaging messaging;
  late NoPopups popups;
  late FakePushSession session;
  late List<PushTarget> opened;
  late DateTime now;

  Future<ProviderContainer> launch({
    bool signedIn = true,
    bool pushAvailable = true,
    bool mustChange = false,
    Completer<void>? restoring,
  }) async {
    SharedPreferences.setMockInitialValues({'push_permission_asked': true});
    final prefs = await SharedPreferences.getInstance();
    session = FakePushSession(
      signedIn: signedIn,
      restoring: restoring,
      mustChangeAtStart: mustChange,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pushAvailableProvider.overrideWithValue(pushAvailable),
        firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
        localNotificationDataSourceProvider.overrideWithValue(popups),
        deviceRemoteDataSourceProvider.overrideWithValue(FakeDeviceRemote()),
        authSessionProvider.overrideWith(() => session),
        pushOpenerProvider.overrideWithValue(opened.add),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pushOpenProvider, (_, _) {});
    addTearDown(sub.close);
    if (restoring == null) await container.read(authSessionProvider.future);
    await _settle();
    return container;
  }

  setUp(() {
    messaging = FakeMessaging();
    popups = NoPopups();
    opened = [];
    now = DateTime(2026, 11, 18, 9);
  });

  test('the same push delivered twice (banner and tray, or iOS twice): '
      'one page', () async {
    await launch();
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    // The same push again a second later, after the first has opened.
    now = now.add(const Duration(seconds: 1));
    popups.taps.add(ot);
    await _settle();
    expect(opened, [const OtRequestTarget('ot-9')]);

    // Tapped again a while later: opens again.
    now = now.add(const Duration(seconds: 10));
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    expect(opened, hasLength(2));
  });

  test('a different push right after: opens too', () async {
    await launch();
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    messaging.opened.add(const PushMessage(data: leave));
    await _settle();
    expect(opened, [
      const OtRequestTarget('ot-9'),
      const LeaveRequestTarget('lr-1'),
    ]);
  });

  test(
    'a tap that started the App waits for the session, then opens once',
    () async {
      messaging.launchedBy = const PushMessage(data: leave);
      final restoring = Completer<void>();
      final container = await launch(restoring: restoring);
      expect(opened, isEmpty);
      expect(
        container.read(pushOpenProvider),
        const LeaveRequestTarget('lr-1'),
      );

      restoring.complete();
      await container.read(authSessionProvider.future);
      await _settle();
      expect(opened, [const LeaveRequestTarget('lr-1')]);
      expect(container.read(pushOpenProvider), isNull);

      // Not again on the next sign-in.
      session.signOut();
      await _settle();
      session.signIn();
      await _settle();
      expect(opened, hasLength(1));
    },
  );

  test(
    'held on the forced password change: opens only after the change',
    () async {
      messaging.launchedBy = const PushMessage(data: leave);
      final container = await launch(mustChange: true);
      expect(opened, isEmpty);

      session.signIn();
      await _settle();
      expect(opened, [const LeaveRequestTarget('lr-1')]);
      expect(container.read(pushOpenProvider), isNull);
    },
  );

  test(
    'signed out: the tap is dropped, and a later sign-in opens nothing',
    () async {
      messaging.launchedBy = const PushMessage(data: leave);
      final container = await launch(signedIn: false);
      expect(container.read(pushOpenProvider), isNull);

      session.signIn();
      await _settle();
      expect(opened, isEmpty);
    },
  );

  test('a sign-out drops a target still waiting (shared phone)', () async {
    messaging.launchedBy = const PushMessage(data: leave);
    final container = await launch(mustChange: true);
    expect(container.read(pushOpenProvider), isNotNull);

    session.signOut();
    await _settle();
    expect(container.read(pushOpenProvider), isNull);
    session.signIn();
    await _settle();
    expect(opened, isEmpty);
  });

  test('a sign-out just after a tap: nothing opens', () async {
    await launch();
    messaging.opened.add(const PushMessage(data: ot));
    // The tap is in (microtasks only), the opener's timer not yet run.
    for (var i = 0; i < 5; i++) {
      await Future<void>.value();
    }
    session.signOut();
    await _settle();
    expect(opened, isEmpty);
  });

  test('a tap from the background opens straight away', () async {
    await launch();
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    expect(opened, [const OtRequestTarget('ot-9')]);
  });

  test('a tap on the App\'s own banner (Android, App open) opens it', () async {
    await launch();
    popups.taps.add(ot);
    await _settle();
    expect(opened, [const OtRequestTarget('ot-9')]);
  });

  test('a banner tap that started the App opens it too', () async {
    popups.launchedBy = leave;
    await launch();
    expect(opened, [const LeaveRequestTarget('lr-1')]);
  });

  test('two taps while starting: the newest wins, one opens', () async {
    final restoring = Completer<void>();
    await launch(restoring: restoring);
    messaging.opened.add(const PushMessage(data: leave));
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    restoring.complete();
    await _settle();
    expect(opened, [const OtRequestTarget('ot-9')]);
  });

  test('Firebase did not start: nothing is read, nothing opens', () async {
    messaging.launchedBy = const PushMessage(data: leave);
    final container = await launch(pushAvailable: false);
    messaging.opened.add(const PushMessage(data: ot));
    await _settle();
    expect(opened, isEmpty);
    expect(container.read(pushOpenProvider), isNull);
  });
}

/// Microtasks and the zero timer the opener runs on.
Future<void> _settle() async {
  await pumpEventQueue();
  await Future<void>.delayed(Duration.zero);
  await pumpEventQueue();
}
