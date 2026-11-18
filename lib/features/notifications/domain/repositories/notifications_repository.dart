import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';

/// The bell list (#54).
abstract class NotificationsRepository {
  /// One page of the caller's notifications, newest first.
  FutureResult<NumberedPage<AppNotification>> notifications({int page = 1});
}
