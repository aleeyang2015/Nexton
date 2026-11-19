import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/notifications_repository.dart';

/// Marks one row of the bell list read (#55): the row's id.
class MarkNotificationReadUseCase implements BaseUseCase<Unit, String> {
  final NotificationsRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  @override
  FutureResult<Unit> call(String id) => _repository.markRead(id);
}
