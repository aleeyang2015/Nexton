/// Body of `POST /mobile/devices`.
class DeviceRegistrationModel {
  final String deviceId;

  /// `ios`, `android` or `web`.
  final String deviceType;
  final String deviceToken;
  final String? appVersion;

  const DeviceRegistrationModel({
    required this.deviceId,
    required this.deviceType,
    required this.deviceToken,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_type': deviceType,
    'device_token': deviceToken,
    if (appVersion != null) 'app_version': appVersion,
  };
}
