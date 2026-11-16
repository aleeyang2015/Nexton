import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/push_message.dart';

/// Thin wrapper over [FirebaseMessaging] so the repository never touches the
/// plugin's static API directly.
abstract class FirebaseMessagingDataSource {
  /// True when the user allowed notifications (or chose provisional on iOS).
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onMessage;
}

class FirebaseMessagingDataSourceImpl implements FirebaseMessagingDataSource {
  /// How long to wait for APNs to hand iOS its token after launch.
  static const int _apnsAttempts = 5;
  static const Duration _apnsRetryDelay = Duration(seconds: 1);

  final FirebaseMessaging _messaging;

  FirebaseMessagingDataSourceImpl(this._messaging);

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();

    // iOS shows a push that arrives in the foreground only when told to.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
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
  Stream<PushMessage> get onMessage => FirebaseMessaging.onMessage.map(
    (message) => PushMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    ),
  );
}
