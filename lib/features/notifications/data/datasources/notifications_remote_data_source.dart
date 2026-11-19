import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
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

  /// Marks one of the caller's notifications read (#55,
  /// `PUT /mobile/notifications/:id/read`). Doing it again is fine.
  Future<void> markRead(String id);

  /// Marks all of the caller's notifications read (#55,
  /// `PUT /mobile/notifications/read-all`).
  Future<void> markAllRead();

  /// How many of the caller's notifications are unread (#55,
  /// `GET /mobile/notifications/unread-count` → `{count}`).
  Future<int> unreadCount();
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

  @override
  Future<void> markRead(String id) async {
    await _client.put<dynamic>(PushPaths.notificationRead(id));
  }

  @override
  Future<void> markAllRead() async {
    await _client.put<dynamic>(PushPaths.notificationsReadAll);
  }

  @override
  Future<int> unreadCount() async {
    final response = await _client.get<dynamic>(
      PushPaths.notificationsUnreadCount,
    );
    final count = ApiEnvelope.unwrapObject(response.data)['count'];
    // Not a number: not an answer. The caller shows no count, never a 0
    // that would say "nothing new".
    if (count is! num) {
      throw const FormatException('unread-count: no count in the answer');
    }
    return count < 0 ? 0 : count.toInt();
  }
}
