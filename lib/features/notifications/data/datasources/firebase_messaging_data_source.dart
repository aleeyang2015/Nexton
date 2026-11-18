import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/push_message.dart';

/// Thin wrapper over [FirebaseMessaging] so the repository never touches the
/// plugin's static API directly. The only file that imports
/// `firebase_messaging` (#51): the rest of the App, and its tests, see this
/// abstract class (a fake in tests).
abstract class FirebaseMessagingDataSource {
  /// True when the user allowed notifications (or chose provisional on iOS).
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onMessage;

  /// Kills this phone's FCM token (#52, at sign-out): a push the server
  /// still sends to it is refused, and the next sign-in gets a new one.
  Future<void> deleteToken();

  /// The push whose tap started the App, if any (#53).
  Future<PushMessage?> initialMessage();

  /// A push tapped while the App was in the background (#53); on iOS also
  /// the alert shown while it was open.
  Stream<PushMessage> get onMessageOpenedApp;
}

/// Runs in its own isolate when a push arrives while the app is in the
/// background or closed. The system already shows a push that carries a
/// `notification` block, so there is nothing to display here — the handler
/// only has to exist and bring Firebase up for the plugin.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseMessagingDataSourceImpl implements FirebaseMessagingDataSource {
  /// The plugin's own instance; Firebase must have started.
  factory FirebaseMessagingDataSourceImpl.instance() =>
      FirebaseMessagingDataSourceImpl(FirebaseMessaging.instance);

  /// Registers [firebaseMessagingBackgroundHandler]: before `runApp`, so a
  /// push that wakes a closed app has somewhere to go.
  static void registerBackgroundHandler() =>
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  /// How long to wait for APNs to hand iOS its token after launch.
  static const int _apnsAttempts = 5;
  static const Duration _apnsRetryDelay = Duration(seconds: 1);

  final FirebaseMessaging _messaging;

  FirebaseMessagingDataSourceImpl(this._messaging);

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();

    // iOS shows a push that arrives in the foreground only when told to.
    // No number on the App icon (decision 28).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    // On iOS getToken throws until APNs has issued its token, which can lag a
    // second or two behind launch.
    if (Platform.isIOS && !await _waitForApnsToken()) return null;
    // Deprecated in favour of register()/onRegistered, but those yield a
    // Firebase Installation ID, not the registration token the backend sends
    // to (`…:APA91b…` in its POST /mobile/devices sample).
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsAttempts; attempt++) {
      if (await _messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(_apnsRetryDelay);
    }
    return false;
  }

  @override
  // Paired with getToken above; see the note there.
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  // Paired with getToken above: the registration token the backend sends
  // to is the one to kill (unregister() works on the Installation ID).
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<PushMessage> get onMessage => FirebaseMessaging.onMessage.map(_toPush);

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPush(message);
  }

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPush);

  static PushMessage _toPush(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data,
  );
}
