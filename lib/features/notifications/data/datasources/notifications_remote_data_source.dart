import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/paged_list.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';
import 'push_api_paths.dart';

/// The bell list's rows (#54).
abstract class NotificationsRemoteDataSource {
  /// One page of the caller's own notifications, newest first, by page
  /// number (`page`, `per_page`; `meta {page, total_pages}`).
  Future<NumberedPage<AppNotification>> notifications({
    int page = 1,
    int perPage = pageSize,
  });

  /// Rows per page: the server's default.
  static const int pageSize = 20;
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient _client;

  NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<NumberedPage<AppNotification>> notifications({
    int page = 1,
    int perPage = NotificationsRemoteDataSource.pageSize,
  }) async {
    final response = await _client.get<dynamic>(
      PushPaths.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    if (kDebugMode) {
      debugPrint('GET ${PushPaths.notifications} page $page');
    }
    return NumberedPage.fromBody(
      response.data,
      page,
      NotificationModel.fromJson,
    );
  }
}
