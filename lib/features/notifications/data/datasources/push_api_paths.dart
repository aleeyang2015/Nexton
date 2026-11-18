/// The device-registration routes, relative to the client's `/api/v1` base
/// URL.
///
/// Feature-local for the same reason as `LeavePaths`: only the network layer's
/// own routes live in `core/network/api_paths.dart`.
class PushPaths {
  PushPaths._();

  static const String devices = '/mobile/devices';

  /// One device row, by the App's own `device_id` (#52).
  static String device(String deviceId) =>
      '$devices/${Uri.encodeComponent(deviceId)}';
}
