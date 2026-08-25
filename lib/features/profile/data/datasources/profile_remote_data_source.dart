import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/employee_profile.dart';
import '../models/employee_profile_model.dart';
import 'profile_api_paths.dart';

/// The profile call the home header and the profile page can trigger.
///
/// Throws on failure ([AppException], or a [DioException] carrying a mapped
/// Failure); the repository converts those into a Result.
abstract class ProfileRemoteDataSource {
  Future<EmployeeProfile> myProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _client;

  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<EmployeeProfile> myProfile() async {
    final response = await _client.get<dynamic>(ProfilePaths.me);
    return EmployeeProfileModel.fromJson(ApiEnvelope.unwrapObject(response.data));
  }
}
