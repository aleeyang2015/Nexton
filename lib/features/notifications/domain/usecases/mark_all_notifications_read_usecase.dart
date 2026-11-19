import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

/// Marks every row of the bell list read (#55).
class MarkAllNotificationsReadUseCase implements NoParamsUseCase<Unit> {
  final NotificationsRepository _repository;

  MarkAllNotificationsReadUseCase(this._repository);

  @override
  FutureResult<Unit> call() => _repository.markAllRead();
}
