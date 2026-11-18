import '../../../../core/utils/result.dart';
import '../entities/push_message.dart';

/// Push notifications: the permission, the backend's copy of the device token,
/// and the pushes that arrive while the app is open.
abstract class PushNotificationRepository {
  /// Asks the user to allow notifications. Success carries whether they did.
  FutureResult<bool> requestPermission();

  /// Whether the permission was already asked on this phone (#51).
  bool get permissionAsked;
  FutureResult<Unit> markPermissionAsked();

  /// Sends this device's current FCM token to the backend, with its name,
  /// versions and the App's language [languageCode] (#52).
  FutureResult<Unit> registerDevice({required String languageCode});

  /// A new FCM token: `PUT` it; a server with no active row for this phone
  /// gets the full registration instead (#52).
  FutureResult<Unit> updateDeviceToken({required String languageCode});

  /// Signs this phone off (#52): `DELETE` the backend's row (a `404` counts
  /// as done).
  FutureResult<Unit> unregisterDevice();

  /// Kills this phone's FCM token (#52).
  FutureResult<Unit> deleteToken();

  /// Fires with each new token FCM issues; the backend must be told again.
  Stream<String> get onTokenRefresh;

  /// Pushes received while the app is in the foreground.
  Stream<PushMessage> get onForegroundMessage;

  /// Shows [message] as a banner. Only Android needs this — iOS presents
  /// foreground pushes itself.
  FutureResult<Unit> showForeground(PushMessage message);

  /// The `data` of each push the user taps while the App runs (#53): the
  /// system's push from the background, or the App's own banner.
  Stream<Map<String, String>> get openedPushes;

  /// The `data` of the push whose tap started the App, if any (#53).
  FutureResult<Map<String, String>?> launchPush();
}
