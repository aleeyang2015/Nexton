import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Coordinates the remote and local sources, and converts thrown
/// exceptions into [Result] via [BaseRepository.guard].
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  FutureResult<User> login({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final model = await _remote.login(email: email, password: password);
      await _local.writeUser(model);
      return model.toEntity();
    });
  }

  @override
  FutureResult<Unit> logout() {
    return guard(() async {
      await _remote.logout();
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
