import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_info.dart';
import '../repositories/app_info_repository.dart';

/// Which App build to ask about: `android` or `ios`, and its version.
class AppBuild {
  final String platform;
  final String version;

  const AppBuild({required this.platform, required this.version});
}

/// The server's word on this App build (#57).
class GetAppInfoUseCase implements BaseUseCase<AppInfo, AppBuild> {
  final AppInfoRepository _repository;

  GetAppInfoUseCase(this._repository);

  @override
  FutureResult<AppInfo> call(AppBuild build) =>
      _repository.appInfo(platform: build.platform, version: build.version);
}
