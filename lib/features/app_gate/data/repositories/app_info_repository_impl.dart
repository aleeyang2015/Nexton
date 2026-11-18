import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/repositories/app_info_repository.dart';
import '../datasources/app_info_remote_data_source.dart';

class AppInfoRepositoryImpl extends BaseRepository
    implements AppInfoRepository {
  final AppInfoRemoteDataSource _remote;

  AppInfoRepositoryImpl(this._remote);

  @override
  FutureResult<AppInfo> appInfo({
    required String platform,
    required String version,
  }) => guard(() => _remote.appInfo(platform: platform, version: version));
}
