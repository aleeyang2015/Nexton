/// The device-registration routes, relative to the client's `/api/v1` base
/// URL.
///
/// Feature-local for the same reason as `LeavePaths`: only the network layer's
/// own routes live in `core/network/api_paths.dart`.
class PushPaths {
  PushPaths._();

  static const String devices = '/mobile/devices';

  /// The caller's own notifications, newest first (#54).
  static const String notifications = '/mobile/notifications';

  /// Marks one of the caller's notifications read (#55).
  static String notificationRead(String id) =>
      '$notifications/${Uri.encodeComponent(id)}/read';

  /// Marks all of the caller's notifications read (#55).
  static const String notificationsReadAll = '$notifications/read-all';

  /// How many of the caller's notifications are unread (#55).
  static const String notificationsUnreadCount = '$notifications/unread-count';

  /// One device row, by the App's own `device_id` (#52).
  static String device(String deviceId) =>
      '$devices/${Uri.encodeComponent(deviceId)}';
}
