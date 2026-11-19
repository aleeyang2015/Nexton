import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/domain/entities/push_message.dart';
import 'package:next_on/features/notifications/domain/push_route.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/push_notifications_notifier.dart';
import 'package:next_on/features/notifications/presentation/providers/push_open_notifier.dart';
import 'package:next_on/features/notifications/presentation/push_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/push_test_doubles.dart';

/// A push that arrives while the App is open (#53, owner's decision of
/// 13 Nov): the phone shows the App's own pop-up, and a tap on it opens the
/// push's item.
void main() {
  const leavePush = PushMessage(
    title: 'Leave approved',
    body: 'Your leave on 24 Nov was approved.',
    data: {
      'notification_type': 'leave_request',
      'reference_type': 'leave_request',
      'reference_id': 'lr-1',
    },
  );

  late FakeMessaging messaging;
  late NoPopups popups;
  late List<PushTarget> opened;

  setUp(() {
    messaging = FakeMessaging();
    popups = NoPopups();
    opened = [];
  });

  /// The App, open on [platform], with both push notifiers started as
  /// `app.dart` starts them.
  Future<ProviderContainer> launch({
    TargetPlatform platform = TargetPlatform.android,
    bool signedIn = true,
    bool pushAvailable = true,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    SharedPreferences.setMockInitialValues({'push_permission_asked': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pushAvailableProvider.overrideWithValue(pushAvailable),
        firebaseMessagingDataSourceProvider.overrideWithValue(messaging),
        localNotificationDataSourceProvider.overrideWithValue(popups),
        deviceRemoteDataSourceProvider.overrideWithValue(FakeDeviceRemote()),
        authSessionProvider.overrideWith(
          () => FakePushSession(signedIn: signedIn),
        ),
        pushOpenerProvider.overrideWithValue((t) async => opened.add(t)),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
      ],
    );
    addTearDown(container.dispose);
    final push = container.listen(pushNotificationsProvider, (_, _) {});
    final open = container.listen(pushOpenProvider, (_, _) {});
    addTearDown(push.close);
    addTearDown(open.close);
    await container.read(authSessionProvider.future);
    await pumpEventQueue();
    return container;
  }

  test('on Android a push that arrives while the App is open shows the '
      'App\'s pop-up, with the push\'s own title, text and data', () async {
    await launch();

    messaging.foreground.add(leavePush);
    await pumpEventQueue();

    expect(popups.shown, [leavePush]);
  });

  test('a tap on that pop-up opens the push\'s item', () async {
    await launch();
    messaging.foreground.add(leavePush);
    await pumpEventQueue();
    expect(opened, isEmpty, reason: 'nothing opens before the tap');

    // The pop-up carries the push's data; the tap hands it back.
    popups.taps.add({
      for (final e in popups.shown.single.data.entries) e.key: '${e.value}',
    });
    await pumpEventQueue();

    expect(opened, [const LeaveRequestTarget('lr-1')]);
  });

  test('each push gets its own pop-up, in the order they arrived', () async {
    await launch();
    const second = PushMessage(title: 'OT approved', body: 'Tonight, 18:00');

    messaging.foreground
      ..add(leavePush)
      ..add(second);
    await pumpEventQueue();

    expect(popups.shown, [leavePush, second]);
  });

  test('a push with no title and no text shows nothing', () async {
    await launch();

    messaging.foreground.add(
      const PushMessage(data: {'notification_type': 'leave_request'}),
    );
    await pumpEventQueue();

    expect(popups.shown, isEmpty);
  });

  test('on iOS the App adds no pop-up of its own: the system shows the '
      'push', () async {
    await launch(platform: TargetPlatform.iOS);

    messaging.foreground.add(leavePush);
    await pumpEventQueue();

    expect(popups.shown, isEmpty);
  });

  test('a pop-up that could not be shown does not stop the next one', () async {
    await launch();
    popups.showError = Exception('plugin failed');
    messaging.foreground.add(leavePush);
    await pumpEventQueue();
    expect(popups.shown, isEmpty);

    popups.showError = null;
    messaging.foreground.add(leavePush);
    await pumpEventQueue();

    expect(popups.shown, [leavePush]);
  });

  test('when Firebase did not start, nothing listens for pushes', () async {
    await launch(pushAvailable: false);

    expect(messaging.foreground.hasListener, isFalse);
  });
}
