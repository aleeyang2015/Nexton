import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'push_constants.dart';

/// The `device_id` the backend keys registrations on.
///
/// Generated once and kept in SharedPreferences, so re-registering after a
/// token refresh or a new login updates the same row instead of adding one.
/// A reinstall clears it, which is also when the old FCM token dies.
abstract class DeviceLocalDataSource {
  String deviceId();

  /// Whether the notification permission was already asked on this phone
  /// (#51): asked once, never again after a refusal.
  bool permissionAsked();
  Future<void> markPermissionAsked();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  final SharedPreferences _prefs;

  DeviceLocalDataSourceImpl(this._prefs);

  @override
  String deviceId() {
    final stored = _prefs.getString(PushConstants.deviceIdKey);
    if (stored != null) return stored;

    final id = _randomHex(16);
    _prefs.setString(PushConstants.deviceIdKey, id);
    return id;
  }

  @override
  bool permissionAsked() =>
      _prefs.getBool(PushConstants.permissionAskedKey) ?? false;

  @override
  Future<void> markPermissionAsked() =>
      _prefs.setBool(PushConstants.permissionAskedKey, true);

  static String _randomHex(int bytes) {
    final random = Random.secure();
    return List.generate(
      bytes,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
