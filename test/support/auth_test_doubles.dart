import 'dart:async';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/secure_store.dart';
import 'package:next_on/core/network/session_end_reason.dart';
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

  /// The next read of a key waits for the completer set here, then reads:
  /// a keychain step that is slow, so another can start meanwhile.
  final Map<String, Completer<void>> holdRead = {};

  /// The next delete of a key waits for the completer set here.
  final Map<String, Completer<void>> holdDelete = {};

  @override
  Future<String?> read(String key) async {
    await holdRead.remove(key)?.future;
    return values[key];
  }

  /// A write of a key in here throws, as a keychain that refuses it.
  final Set<String> failWrite = {};

  @override
  Future<void> write(String key, String value) async {
    if (failWrite.contains(key)) throw StateError('keychain refused $key');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    await holdDelete.remove(key)?.future;
    values.remove(key);
  }
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
    final answer = profile;
    final error = profileError;
    final hold = holdProfile;
    holdProfile = null;
    await hold?.future;
    if (error != null) throw error;
    return answer!;
  }

  /// When set, the next [fetchProfile] waits for it before answering with
  /// what was set when it was called.
  Completer<void>? holdProfile;

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

  /// The refresh token of each server logout (#56).
  final List<String> logouts = [];
  Duration? lastLogoutTimeout;
  Object? logoutError;

  /// When set, the logout waits for it (a server that never answers).
  Completer<void>? holdLogout;

  /// Called at the logout, to tell its order against other calls.
  void Function()? onLogout;

  @override
  Future<void> logout(String refreshToken, {Duration? timeout}) async {
    logouts.add(refreshToken);
    lastLogoutTimeout = timeout;
    onLogout?.call();
    await holdLogout?.future;
    if (logoutError != null) throw logoutError!;
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

  /// What the last [login] was called with.
  String? lastLoginEmail;
  String? lastLoginPassword;
  int loginCalls = 0;

  final sessionExpired = StreamController<SessionEndReason>.broadcast();

  @override
  Stream<SessionEndReason> get onSessionExpired => sessionExpired.stream;

  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
    bool Function()? abandonIf,
  }) async {
    loginCalls++;
    lastLoginEmail = email;
    lastLoginPassword = password;
    await whileLoggingIn?.call();
    // As the real one: once the server has answered, and again once the
    // pair is stored and the profile read, the caller may have left (#93);
    // then the new sign-in is ended, and a failure comes back.
    if (abandonIf?.call() ?? false) return _abandon();
    await afterStored?.call();
    if (abandonIf?.call() ?? false) return _abandon();
    return loginResult;
  }

  Future<Result<AuthSession>> _abandon() async {
    abandonedLogins++;
    await whileAbandoning?.call();
    return const Result.failure(Failure.unknown(message: 'left'));
  }

  /// Sign-ins whose caller had left (#93), ended by the sign-in itself.
  int abandonedLogins = 0;

  /// Runs once a sign-in has stored its pair, before its profile is read.
  Future<void> Function()? afterStored;

  /// Runs while an abandoned sign-in ends its pair on the server (up to
  /// 5 s on a real phone).
  Future<void> Function()? whileAbandoning;

  /// Runs while a login is on its way: what the App does meanwhile (#60: the
  /// login screen is left, and its form disposed, before the answer).
  Future<void> Function()? whileLoggingIn;

  /// Runs while a restore is in flight, before it answers: where a test can
  /// have the network layer give up on the session mid-restore.
  Future<void> Function()? whileRestoring;

  @override
  FutureResult<AuthSession> restoreSession() async {
    restoreCalls++;
    await whileRestoring?.call();
    return restoreResult;
  }

  int restoreCalls = 0;

  /// When set, the next [fetchProfile] waits for it before answering with
  /// the [profileResult] set when it was called.
  Completer<void>? holdProfile;

  @override
  FutureResult<User> fetchProfile() async {
    fetchProfileCalls++;
    final answer = profileResult;
    final hold = holdProfile;
    holdProfile = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<Unit> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    await whileChangingPassword?.call();
    return changePasswordResult;
  }

  /// Runs while a password change is on its way, before it answers (#91).
  Future<void> Function()? whileChangingPassword;

  /// The `endSession` of each logout (#56).
  final List<bool> logoutEndSession = [];

  /// Called at each logout, to tell its order against other calls.
  void Function({required bool endSession})? onLogout;

  @override
  FutureResult<Unit> logout({bool endSession = false}) async {
    logoutCalls++;
    logoutEndSession.add(endSession);
    onLogout?.call(endSession: endSession);
    return const Result.success(Unit.instance);
  }

  @override
  FutureResult<User?> currentUser() async =>
      Result.success(profileResult.dataOrNull);
}

/// The `/auth/me` sample from auth.md, as a model.
UserModel testUserModel({
  String id = 'cce14a0e',
  bool? isDepartmentHead,
  List<String> roles = const ['employee'],
  List<String> permissions = const ['corehr:employee:read'],
  String? employeeId = 'b3f1-employees-uuid',
  // A company with everything the App uses (#61); a test of a smaller one
  // passes its own.
  List<String> modules = const ['core_hr', 'payroll'],
}) => UserModel(
  id: id,
  tenantId: 'cbc6553a',
  email: 'somphone.vilaysone@nexton.la',
  firstName: 'Somphone',
  lastName: 'Vilaysone',
  roles: roles,
  permissions: permissions,
  modules: modules,
  employeeId: employeeId,
  isDepartmentHead: isDepartmentHead,
);

User testUser({
  String id = 'cce14a0e',
  List<String> modules = const ['core_hr', 'payroll'],
}) => testUserModel(id: id, modules: modules).toEntity();

LoginResponseModel testTokens({
  bool mustChangePassword = false,
  DateTime? expiresAt,
  bool isDepartmentHead = false,
}) => LoginResponseModel(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  mustChangePassword: mustChangePassword,
  expiresAt: expiresAt,
  isDepartmentHead: isDepartmentHead,
);
