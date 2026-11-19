/// Names the native side has to agree on.
class PushConstants {
  PushConstants._();

  /// Android channel for every push. AndroidManifest.xml names the same id as
  /// FCM's default channel, so a push delivered while the app is closed lands
  /// on it too.
  static const String androidChannelId = 'nexton_push';
  static const String androidChannelName = 'Notifications';

  /// SharedPreferences key for the app-generated device id.
  static const String deviceIdKey = 'push_device_id';

  /// The notification permission was asked once (#51).
  static const String permissionAskedKey = 'push_permission_asked';

  /// The white-on-transparent tray icon (the Nexton mark, one PNG per
  /// density in `res/drawable-*dpi`), for the system's pushes and the App's
  /// own pop-up.
  static const String androidSmallIcon = '@drawable/ic_stat_nexton';
}
