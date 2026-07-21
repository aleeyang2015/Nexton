import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Remote calls this feature needs. Throws [AppException] on failure —
/// the repository converts those into a Result.
abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}

/// Talks to the real backend. Wire this up once the API exists by
/// swapping the datasource binding in auth_providers.dart.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final body = response.data;
    if (body == null) {
      throw const ServerException('Empty response from server');
    }

    return UserModel.fromJson(body['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() => _client.post<void>('/auth/logout');
}

/// Stand-in until the backend is ready. Accepts any password of a valid
/// length and echoes the email back as a user.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _latency = Duration(milliseconds: 800);

  /// The one credential pair the fake treats as wrong, so the error
  /// path stays exercisable in the UI.
  static const rejectedEmail = 'wrong@example.com';

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_latency);

    if (email.toLowerCase() == rejectedEmail) {
      throw const AuthException(
        'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',
        code: 'INVALID_CREDENTIALS',
      );
    }

    return UserModel(
      id: 'mock-user-1',
      email: email,
      displayName: 'ໝ່ຳ ຈົກມົກ',
      avatarUrl: null,
      jobTitle: 'ນັກພັດທະນາແອັບມືຖື',
    );
  }

  @override
  Future<void> logout() => Future.delayed(_latency);
}
