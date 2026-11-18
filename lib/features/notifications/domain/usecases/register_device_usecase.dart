import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/push_notification_repository.dart';

/// Asks for notification permission — once on this phone, after sign-in
/// (#51): a refusal is never asked again — then registers the device with
/// the backend. A refused permission still registers: the user can turn
/// notifications on later in system settings, and the token stays valid.
class RegisterDeviceUseCase implements NoParamsUseCase<Unit> {
  final PushNotificationRepository _repository;

  RegisterDeviceUseCase(this._repository);

  @override
  FutureResult<Unit> call() async {
    if (!_repository.permissionAsked) {
      final asked = await _repository.requestPermission();
      // Asked (allowed or refused): not again. A prompt that could not be
      // shown (the plugin threw) is tried at the next sign-in.
      if (asked.isSuccess) await _repository.markPermissionAsked();
    }
    return _repository.registerDevice();
  }
}
