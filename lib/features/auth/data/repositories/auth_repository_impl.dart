import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/auth_failure_x.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Coordinates the remote and local sources, and converts thrown
/// exceptions into [Result] via [BaseRepository.guard].
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  /// How long the cold start waits for `/auth/me` when there is no cached
  /// profile to paint in the meantime.
  static const Duration bootstrapTimeout = Duration(seconds: 5);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final Stream<void> _sessionExpired;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required Stream<void> sessionExpired,
  }) : _remote = remote,
       _local = local,
       _sessionExpired = sessionExpired;

  @override
  Stream<void> get onSessionExpired => _sessionExpired;

  /// Login is atomic: tokens are written first (the profile call needs them),
  /// and rolled back if anything after that fails — so a half-finished login
  /// can never auto-authenticate on the next cold start.
  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final tokens = await _remote.login(email: email, password: password);

      await _local.writeTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      // Only the login response reports this, and only once — persist it so a
      // restart can't walk around the change-password requirement.
      await _local.writeMustChangePassword(tokens.mustChangePassword);

      try {
        final user = await _remote.fetchProfile();
        await _local.writeUser(user);

        return AuthSession.signedIn(
          user.toEntity(),
          mustChangePassword: tokens.mustChangePassword,
        );
      } catch (_) {
        await _local.clear();
        rethrow;
      }
    });
  }

  /// Cold start. Paints from cache when there is one and revalidates; only a
  /// credential failure evicts the session — being offline must not sign the
  /// user out.
  @override
  FutureResult<AuthSession> restoreSession() {
    return guard(() async {
      if (!await _local.hasTokens()) {
        return const AuthSession.unauthenticated();
      }

      final cached = await _local.readUser();
      // Survives the restart; `/auth/me` never re-reports it.
      final mustChange = await _local.readMustChangePassword();

      try {
        final user = await _remote.fetchProfile(
          timeout: cached == null ? bootstrapTimeout : null,
        );
        await _local.writeUser(user);
        return AuthSession.signedIn(
          user.toEntity(),
          mustChangePassword: mustChange,
        );
      } catch (error) {
        final failure = toFailure(error);

        if (failure.isSessionFailure) {
          await _local.clear();
          return const AuthSession.unauthenticated();
        }

        // Transport blip: keep the optimistic identity, retry on next resume.
        // The pending change survives it — an offline start must not be a way
        // around the requirement.
        if (cached != null) {
          return AuthSession.signedIn(
            cached.toEntity(),
            mustChangePassword: mustChange,
          );
        }

        throw failure;
      }
    });
  }

  @override
  FutureResult<User> fetchProfile() {
    return guard(() async {
      final user = await _remote.fetchProfile();
      await _local.writeUser(user);
      return user.toEntity();
    });
  }

  /// Note: the backend stamps `password_set_at`, which kills every outstanding
  /// refresh token. The current access token keeps working until it expires,
  /// and the next 401 will force a re-login.
  @override
  FutureResult<Unit> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return guard(() async {
      await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // The requirement is discharged; drop it before anyone re-reads it.
      await _local.writeMustChangePassword(false);
      return Unit.instance;
    });
  }

  /// There is no `POST /auth/logout`; teardown is local and the refresh token
  /// is left to lapse server-side.
  @override
  FutureResult<Unit> logout() {
    return guard(() async {
      await _local.clear();
      return Unit.instance;
    });
  }

  @override
  FutureResult<User?> currentUser() {
    return guard(() async {
      final model = await _local.readUser();
      return model?.toEntity();
    });
  }
}
