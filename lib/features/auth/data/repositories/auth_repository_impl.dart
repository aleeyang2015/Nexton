import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/session_end_reason.dart';
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
  final Stream<SessionEndReason> _sessionExpired;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required Stream<SessionEndReason> sessionExpired,
  }) : _remote = remote,
       _local = local,
       _sessionExpired = sessionExpired;

  @override
  Stream<SessionEndReason> get onSessionExpired => _sessionExpired;

  /// Login is atomic: tokens are written first (the profile call needs them),
  /// and rolled back if anything after that fails — so a half-finished login
  /// can never auto-authenticate on the next cold start.
  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
    bool Function()? abandonIf,
  }) {
    return guard(() async {
      final tokens = await _remote.login(email: email, password: password);

      // The user left while this sign-in was on its way (#93: "Sign out"
      // during a password change). This answer is the one place that holds
      // the new refresh token for sure: a sign-out already on its way has
      // read the old one. So it is ended here, and never stored.
      if (abandonIf?.call() ?? false) {
        await _endOnServer(tokens.refreshToken);
        throw const Failure.unknown(message: abandonedMessage);
      }

      await _local.writeTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
      );

      // Only the login response reports this, and only once — persist it so a
      // restart can't walk around the change-password requirement.
      await _local.writeMustChangePassword(tokens.mustChangePassword);

      try {
        // `/auth/me` says whether the user heads a department, and wins; an
        // older server that does not say leaves the login answer's.
        final user = (await _remote.fetchProfile()).withDepartmentHead(
          tokens.isDepartmentHead,
        );
        // Asked again: "Sign out" may have come after the first answer, and
        // a sign-out that read the refresh token before this pair was
        // written sent the old one (#93). The pair is ended here too (a
        // second logout of it does no harm), removed from the phone while it
        // is still the stored one (not someone's sign-in made since), and
        // the profile is not kept.
        if (abandonIf?.call() ?? false) {
          await _endOnServer(tokens.refreshToken);
          await _local.clearIfRefreshIs(tokens.refreshToken);
          throw const Failure.unknown(message: abandonedMessage);
        }
        await _local.writeUser(user);

        return AuthSession.signedIn(
          user.toEntity(),
          mustChangePassword: tokens.mustChangePassword,
        );
      } on Failure catch (failure) {
        if (failure.message == abandonedMessage) rethrow;
        await _local.clear();
        rethrow;
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
        final user = (await _remote.fetchProfile(
          timeout: cached == null ? bootstrapTimeout : null,
        )).withDepartmentHead(cached?.isDepartmentHead);
        await _local.writeUser(user);
        return AuthSession.signedIn(
          user.toEntity(),
          mustChangePassword: mustChange,
        );
      } catch (error) {
        final failure = toFailure(error);

        // The server answered and will not give this token its profile: a
        // dead session, or a refusal with a code (`FORBIDDEN`,
        // `TENANT_MISMATCH`, …). Neither is a blip that the cached identity
        // should paper over, and leaving the tokens behind would send them
        // along with the next login.
        if (failure.isSessionFailure || _isServerRefusal(failure)) {
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

  /// A 400/403 the server sent with an `error.code`. A [ValidationFailure]
  /// with no code is the client's own (an unreadable body), not a refusal.
  static bool _isServerRefusal(Failure failure) =>
      failure is ValidationFailure && failure.code != null;

  @override
  FutureResult<User> fetchProfile() {
    return guard(() async {
      // An older server that does not say keeps what was known.
      final cached = await _local.readUser();
      final user = (await _remote.fetchProfile()).withDepartmentHead(
        cached?.isDepartmentHead,
      );
      // Saved only while that user is still the one signed in on the phone:
      // an answer that lands after a sign-out (or another user's sign-in)
      // must not put the last user's profile back on disk.
      final now = await _local.readUser();
      if (now != null && now.id == user.id && await _local.hasTokens()) {
        await _local.writeUser(user);
      }
      return user.toEntity();
    });
  }

  /// Note: the backend stamps `password_set_at`, which kills every outstanding
  /// refresh token, while the current access token keeps working until it
  /// expires. [AuthSessionNotifier.changePassword] signs in again with the new
  /// password straight after, so the stored pair is one that still refreshes.
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

  /// How long a sign-out waits for the server's logout.
  static const Duration logoutTimeout = Duration(seconds: 5);

  /// Drops the session on the phone. With [endSession] (the user signed
  /// out, and the tokens still work) the server ends this phone's sign-in
  /// first (#56, `POST /auth/logout`), so a copy of the refresh token stops
  /// working. That call is bounded by [logoutTimeout] and any failure is
  /// ignored: the phone's copy is cleared whatever happened, and a refresh
  /// token the server never heard about dies with its `JWT_REFRESH_TTL`.
  @override
  FutureResult<Unit> logout({bool endSession = false}) {
    return guard(() async {
      if (endSession) await _endSessionOnServer();
      await _local.clear();
      return Unit.instance;
    });
  }

  Future<void> _endSessionOnServer() async {
    final String? refreshToken;
    try {
      refreshToken = await _local.readRefreshToken();
    } catch (error) {
      if (kDebugMode) debugPrint('Server logout skipped: $error');
      return;
    }
    if (refreshToken == null || refreshToken.isEmpty) return;
    await _endOnServer(refreshToken);
  }

  /// `POST /auth/logout` for [refreshToken], at most [logoutTimeout]; any
  /// failure is ignored (it lapses at its `JWT_REFRESH_TTL`).
  Future<void> _endOnServer(String refreshToken) async {
    try {
      await _remote
          .logout(refreshToken, timeout: logoutTimeout)
          .timeout(logoutTimeout);
    } catch (error) {
      if (kDebugMode) debugPrint('Server logout skipped: $error');
    }
  }

  /// The failure a sign-in the user left comes back with ([login]'s
  /// `abandonIf`). Never shown: the caller knows the user left.
  static const String abandonedMessage = 'sign-in left before it was stored';

  @override
  FutureResult<User?> currentUser() {
    return guard(() async {
      final model = await _local.readUser();
      return model?.toEntity();
    });
  }
}
