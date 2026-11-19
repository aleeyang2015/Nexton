import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';

/// The bell list (#54), and what is read in it (#55).
abstract class NotificationsRepository {
  /// One page of the caller's notifications, newest first.
  FutureResult<NumberedPage<AppNotification>> notifications({int page = 1});

  /// Marks the notification [id] read.
  FutureResult<Unit> markRead(String id);

  /// Marks all of the caller's notifications read.
  FutureResult<Unit> markAllRead();

  /// How many of the caller's notifications are unread.
  FutureResult<int> unreadCount();
}
