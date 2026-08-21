import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/api_response.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// The three auth calls a screen can trigger. `POST /auth/refresh` is missing
/// on purpose — it is driven by the 401 interceptor, never by a caller — and
/// there is no logout endpoint at all.
///
/// Throws on failure ([AppException], or a [DioException] carrying a mapped
/// Failure); the repository converts those into a Result.
abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });

  /// [timeout] bounds the cold-start probe so a dead network can't hold the
  /// splash screen open.
  Future<UserModel> fetchProfile({Duration? timeout});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<dynamic>(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );

    return LoginResponseModel.fromJson(ApiEnvelope.unwrapObject(response.data));
  }

  @override
  Future<UserModel> fetchProfile({Duration? timeout}) async {
    final response = await _client.get<dynamic>(
      ApiPaths.me,
      options: timeout == null
          ? null
          : Options(receiveTimeout: timeout, sendTimeout: timeout),
    );

    final data = ApiEnvelope.unwrapObject(response.data);
    if (data['id'] is! String) {
      throw const ServerException('Profile response missing id');
    }

    return UserModel.fromJson(data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Any 2xx counts; the `{ message }` body carries nothing the app needs.
    await _client.put<dynamic>(
      ApiPaths.changePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }
}
