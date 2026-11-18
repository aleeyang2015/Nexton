import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/device_registration_model.dart';
import 'push_api_paths.dart';

/// The backend's copy of this phone (#52): register, a new token, and the
/// sign-off at sign-out.
abstract class DeviceRemoteDataSource {
  /// `POST /mobile/devices`: an upsert on `(user, device_id)`.
  Future<void> register(DeviceRegistrationModel body);

  /// `PUT /mobile/devices/:device_id` with the new FCM token. False when the
  /// server has no active row for this phone (`404`): register it instead.
  Future<bool> updateToken(String deviceId, String deviceToken);

  /// `DELETE /mobile/devices/:device_id`: the row goes inactive, its token
  /// dropped. A `404` (already off) counts as done.
  Future<void> unregister(String deviceId);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiClient _client;

  DeviceRemoteDataSourceImpl(this._client);

  @override
  Future<void> register(DeviceRegistrationModel body) async {
    // Any 2xx counts; the response carries nothing the app needs.
    await _client.post<dynamic>(PushPaths.devices, data: body.toJson());
  }

  @override
  Future<bool> updateToken(String deviceId, String deviceToken) async {
    try {
      await _client.put<dynamic>(
        PushPaths.device(deviceId),
        data: {'device_token': deviceToken},
      );
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  @override
  Future<void> unregister(String deviceId) async {
    try {
      await _client.delete<dynamic>(PushPaths.device(deviceId));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return;
      rethrow;
    }
  }
}
