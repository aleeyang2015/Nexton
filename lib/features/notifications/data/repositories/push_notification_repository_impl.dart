import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/push_message.dart';
import '../../domain/repositories/push_notification_repository.dart';
import '../datasources/device_local_data_source.dart';
import '../datasources/device_remote_data_source.dart';
import '../datasources/firebase_messaging_data_source.dart';
import '../datasources/local_notification_data_source.dart';
import '../models/device_registration_model.dart';

class PushNotificationRepositoryImpl extends BaseRepository
    implements PushNotificationRepository {
  final FirebaseMessagingDataSource _messaging;
  final LocalNotificationDataSource _localNotifications;
  final DeviceRemoteDataSource _remote;
  final DeviceLocalDataSource _local;

  PushNotificationRepositoryImpl({
    required FirebaseMessagingDataSource messaging,
    required LocalNotificationDataSource localNotifications,
    required DeviceRemoteDataSource remote,
    required DeviceLocalDataSource local,
  }) : _messaging = messaging,
       _localNotifications = localNotifications,
       _remote = remote,
       _local = local;

  @override
  FutureResult<bool> requestPermission() => guard(_messaging.requestPermission);

  @override
  FutureResult<Unit> registerDevice() {
    return guard(() async {
      final token = await _messaging.getToken();
      if (token == null) {
        // iOS without an APNs token: usually a simulator, or the Push
        // Notifications capability missing from the signing profile.
        throw const Failure.unknown(message: 'No FCM token available');
      }

      await _remote.register(
        DeviceRegistrationModel(
          deviceId: _local.deviceId(),
          deviceType: Platform.isIOS ? 'ios' : 'android',
          deviceToken: token,
          appVersion: AppConstants.appVersion,
        ),
      );
      return Unit.instance;
    });
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage => _messaging.onMessage;

  @override
  FutureResult<Unit> showForeground(PushMessage message) {
    return guard(() async {
      if (Platform.isAndroid && message.hasContent) {
        await _localNotifications.show(message);
      }
      return Unit.instance;
    });
  }
}
