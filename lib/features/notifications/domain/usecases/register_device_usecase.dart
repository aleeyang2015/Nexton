import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/push_notification_repository.dart';

/// Asks for notification permission, then registers the device with the
/// backend. A refused permission still registers: the user can turn
/// notifications on later in system settings, and the token stays valid.
class RegisterDeviceUseCase implements NoParamsUseCase<Unit> {
  final PushNotificationRepository _repository;

  RegisterDeviceUseCase(this._repository);

  @override
  FutureResult<Unit> call() async {
    await _repository.requestPermission();
    return _repository.registerDevice();
  }
}
