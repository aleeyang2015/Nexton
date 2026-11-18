import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/entities/app_info.dart';
import '../models/app_info_model.dart';

/// `GET /mobile/app-info` (#57): public, the same for every company.
abstract class AppInfoRemoteDataSource {
  Future<AppInfo> appInfo({required String platform, required String version});

  static const String path = '/mobile/app-info';

  /// The check never waits longer: the App carries on without it.
  static const Duration timeout = Duration(seconds: 5);
}

/// On a Dio of its own with no auth interceptor: it works signed out, sends
/// no token, and can never start a refresh or end a session.
class AppInfoRemoteDataSourceImpl implements AppInfoRemoteDataSource {
  final Dio _dio;

  AppInfoRemoteDataSourceImpl(this._dio);

  @override
  Future<AppInfo> appInfo({
    required String platform,
    required String version,
  }) async {
    final response = await _dio.get<dynamic>(
      AppInfoRemoteDataSource.path,
      queryParameters: {'platform': platform, 'version': version},
      options: Options(
        sendTimeout: AppInfoRemoteDataSource.timeout,
        receiveTimeout: AppInfoRemoteDataSource.timeout,
      ),
    );
    return AppInfoModel.fromJson(ApiEnvelope.unwrapObject(response.data));
  }
}
