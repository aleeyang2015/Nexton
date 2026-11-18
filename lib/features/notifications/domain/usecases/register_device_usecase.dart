import '../../../../core/utils/result.dart';
import '../repositories/push_notification_repository.dart';

/// Asks for notification permission — once on this phone, after sign-in
/// (#51): a refusal is never asked again — then registers the device with
/// the backend. A refused permission still registers: the user can turn
/// notifications on later in system settings, and the token stays valid.
class RegisterDeviceUseCase {
  final PushNotificationRepository _repository;

  /// The prompt on its way, if any: a token refresh that comes meanwhile
  /// waits for it rather than asking a second time.
  Future<void>? _asking;

  RegisterDeviceUseCase(this._repository);

  /// [languageCode]: the App's language, for the server's push text (#52).
  FutureResult<Unit> call({required String languageCode}) async {
    if (!_repository.permissionAsked) {
      await (_asking ??= _askOnce().whenComplete(() => _asking = null));
    }
    return _repository.registerDevice(languageCode: languageCode);
  }

  /// Asked (allowed or refused): not again. A prompt that could not be
  /// shown (the plugin threw), or a flag that could not be saved, is tried
  /// at the next sign-in; the device registers either way.
  Future<void> _askOnce() async {
    final asked = await _repository.requestPermission();
    if (asked.isSuccess) await _repository.markPermissionAsked();
  }
}
