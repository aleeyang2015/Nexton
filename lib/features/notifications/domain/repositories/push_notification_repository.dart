import '../../../../core/utils/result.dart';
import '../entities/push_message.dart';

/// Push notifications: the permission, the backend's copy of the device token,
/// and the pushes that arrive while the app is open.
abstract class PushNotificationRepository {
  /// Asks the user to allow notifications. Success carries whether they did.
  FutureResult<bool> requestPermission();

  /// Sends this device's current FCM token to the backend.
  FutureResult<Unit> registerDevice();

  /// Fires with each new token FCM issues; the backend must be told again.
  Stream<String> get onTokenRefresh;

  /// Pushes received while the app is in the foreground.
  Stream<PushMessage> get onForegroundMessage;

  /// Shows [message] as a banner. Only Android needs this — iOS presents
  /// foreground pushes itself.
  FutureResult<Unit> showForeground(PushMessage message);
}
