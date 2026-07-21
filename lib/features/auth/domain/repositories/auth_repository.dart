import '../../../../core/utils/result.dart';
import '../entities/user.dart';

/// Contract the presentation layer depends on.
/// The implementation lives in data/repositories.
abstract class AuthRepository {
  /// Exchange credentials for a signed-in [User]
  FutureResult<User> login({
    required String email,
    required String password,
  });

  /// Drop the current session
  FutureResult<Unit> logout();

  /// The cached user, or null when nobody is signed in
  FutureResult<User?> currentUser();
}
