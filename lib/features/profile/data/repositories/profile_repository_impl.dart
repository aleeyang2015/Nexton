import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/employee_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<EmployeeProfile> myProfile() => guard(() => _remote.myProfile());
}
