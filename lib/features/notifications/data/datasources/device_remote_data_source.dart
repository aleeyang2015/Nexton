import '../../../../core/network/api_client.dart';
import '../models/device_registration_model.dart';
import 'push_api_paths.dart';

/// Throws on failure; the repository converts that into a Result.
abstract class DeviceRemoteDataSource {
  Future<void> register(DeviceRegistrationModel body);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiClient _client;

  DeviceRemoteDataSourceImpl(this._client);

  @override
  Future<void> register(DeviceRegistrationModel body) async {
    // Any 2xx counts; the response carries nothing the app needs.
    await _client.post<dynamic>(PushPaths.devices, data: body.toJson());
  }
}
