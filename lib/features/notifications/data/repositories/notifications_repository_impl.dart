import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl extends BaseRepository
    implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;

  NotificationsRepositoryImpl(this._remote);

  @override
  FutureResult<NumberedPage<AppNotification>> notifications({int page = 1}) =>
      guard(() => _remote.notifications(page: page));
}
