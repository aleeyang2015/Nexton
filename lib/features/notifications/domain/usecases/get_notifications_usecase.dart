import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// One page of the bell list (#54): the page number, from 1.
class GetNotificationsUseCase
    implements BaseUseCase<NumberedPage<AppNotification>, int> {
  final NotificationsRepository _repository;

  GetNotificationsUseCase(this._repository);

  @override
  FutureResult<NumberedPage<AppNotification>> call(int page) =>
      _repository.notifications(page: page);
}
