import '../../../../core/utils/result.dart';
import '../entities/app_info.dart';

/// The version gate (#57).
abstract class AppInfoRepository {
  /// The server's word on [version] of the App on [platform].
  FutureResult<AppInfo> appInfo({
    required String platform,
    required String version,
  });
}
