/// Body of `POST /mobile/devices` (#52).
///
/// Every field is sent and never empty: `device_name`, `app_version` and
/// `os_version` fit their columns (≤ 255, ≤ 20, ≤ 20).
class DeviceRegistrationModel {
  final String deviceId;

  /// `ios` or `android`.
  final String deviceType;
  final String deviceToken;
  final String deviceName;
  final String appVersion;
  final String osVersion;

  /// The App's language, `lo` or `en`: the server words pushes in it.
  final String locale;

  const DeviceRegistrationModel({
    required this.deviceId,
    required this.deviceType,
    required this.deviceToken,
    required this.deviceName,
    required this.appVersion,
    required this.osVersion,
    required this.locale,
  });

  /// The body for this phone: the values a backend column can hold, none
  /// empty. Pure, for tests: the platform comes in as [isIOS] and
  /// [rawOsVersion].
  factory DeviceRegistrationModel.forPhone({
    required String deviceId,
    required String deviceToken,
    required bool isIOS,
    required String rawOsVersion,
    required String appVersion,
    required String languageCode,
  }) => DeviceRegistrationModel(
    deviceId: deviceId,
    deviceType: isIOS ? 'ios' : 'android',
    deviceToken: deviceToken,
    deviceName: isIOS ? 'iPhone' : 'Android phone',
    appVersion: _fit(appVersion, 20, fallback: '0'),
    osVersion: _fit(rawOsVersion, 20, fallback: isIOS ? 'iOS' : 'Android'),
    locale: languageCode == 'en' ? 'en' : 'lo',
  );

  /// [value] trimmed and cut to [max] characters; [fallback] when empty.
  static String _fit(String value, int max, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= max ? trimmed : trimmed.substring(0, max).trim();
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_type': deviceType,
    'device_token': deviceToken,
    'device_name': deviceName,
    'app_version': appVersion,
    'os_version': osVersion,
    'locale': locale,
  };
}
