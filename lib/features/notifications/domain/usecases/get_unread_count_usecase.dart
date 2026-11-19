import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

/// How many rows of the bell list are unread (#55): the bell's count.
class GetUnreadCountUseCase implements NoParamsUseCase<int> {
  final NotificationsRepository _repository;

  GetUnreadCountUseCase(this._repository);

  @override
  FutureResult<int> call() => _repository.unreadCount();
}
