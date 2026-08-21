import 'dart:async';

import 'package:next_on/core/network/secure_store.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:next_on/features/auth/data/models/login_response_model.dart';
import 'package:next_on/features/auth/data/models/user_model.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/domain/repositories/auth_repository.dart';

/// Keychain stand-in. Backed by a plain map so tests can assert on exactly
/// which keys a flow wrote.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  InMemorySecureStore([Map<String, String>? initial]) {
    if (initial != null) values.addAll(initial);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Programmable remote source: each call either returns the queued value or
/// throws the queued error, and records that it happened.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  LoginResponseModel? loginResponse;
  Object? loginError;

  UserModel? profile;
  Object? profileError;

  Object? changePasswordError;

  int loginCalls = 0;
  int profileCalls = 0;
  int changePasswordCalls = 0;
  Duration? lastProfileTimeout;
  String? lastEmail;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    if (loginError != null) throw loginError!;
    return loginResponse!;
  }

  @override
  Future<UserModel> fetchProfile({Duration? timeout}) async {
    profileCalls++;
    lastProfileTimeout = timeout;
    if (profileError != null) throw profileError!;
    return profile!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    if (changePasswordError != null) throw changePasswordError!;
  }
}

/// Repository stand-in for the notifier tests, where the point is the session
/// state machine rather than the data layer under it.
class FakeAuthRepository implements AuthRepository {
  Result<AuthSession> loginResult = const Result.success(
    AuthSession.unauthenticated(),
  );
  Result<AuthSession> restoreResult = const Result.success(
    AuthSession.unauthenticated(),
  );
  Result<User> profileResult = Result.success(testUser());
  Result<Unit> changePasswordResult = const Result.success(Unit.instance);

  int logoutCalls = 0;
  int changePasswordCalls = 0;
  int fetchProfileCalls = 0;

  final sessionExpired = StreamController<void>.broadcast();

  @override
  Stream<void> get onSessionExpired => sessionExpired.stream;

  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  FutureResult<AuthSession> restoreSession() async => restoreResult;

  @override
  FutureResult<User> fetchProfile() async {
    fetchProfileCalls++;
    return profileResult;
  }

  @override
  FutureResult<Unit> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    return changePasswordResult;
  }

  @override
  FutureResult<Unit> logout() async {
    logoutCalls++;
    return const Result.success(Unit.instance);
  }

  @override
  FutureResult<User?> currentUser() async =>
      Result.success(profileResult.dataOrNull);
}

/// The `/auth/me` sample from auth.md, as a model.
UserModel testUserModel({String id = 'cce14a0e'}) => UserModel(
  id: id,
  tenantId: 'cbc6553a',
  email: 'somphone.vilaysone@nexton.la',
  firstName: 'Somphone',
  lastName: 'Vilaysone',
  roles: const ['employee'],
  permissions: const ['corehr:employee:read'],
  modules: const ['core_hr'],
  employeeId: 'b3f1-employees-uuid',
);

User testUser({String id = 'cce14a0e'}) => testUserModel(id: id).toEntity();

LoginResponseModel testTokens({bool mustChangePassword = false}) =>
    LoginResponseModel(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      mustChangePassword: mustChangePassword,
    );
