import '../models/user_model.dart';

/// Session cache for the signed-in user.
abstract class AuthLocalDataSource {
  Future<UserModel?> readUser();

  Future<void> writeUser(UserModel user);

  Future<void> clear();
}

/// In-memory session — cleared when the process dies.
/// Swap for a shared_preferences/Hive implementation when the app
/// needs to survive a restart; nothing outside this file changes.
class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  UserModel? _cached;

  @override
  Future<UserModel?> readUser() async => _cached;

  @override
  Future<void> writeUser(UserModel user) async => _cached = user;

  @override
  Future<void> clear() async => _cached = null;
}
