import 'dart:io';

import 'package:flutter/foundation.dart';

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
  bool get permissionAsked => _local.permissionAsked();

  @override
  FutureResult<Unit> markPermissionAsked() => guard(() async {
    await _local.markPermissionAsked();
    return Unit.instance;
  });

  @override
  FutureResult<Unit> registerDevice({required String languageCode}) =>
      guard(() async {
        await _register(await _token(), languageCode);
        return Unit.instance;
      });

  @override
  FutureResult<Unit> updateDeviceToken({required String languageCode}) =>
      guard(() async {
        final token = await _token();
        final updated = await _remote.updateToken(_local.deviceId(), token);
        // No active row for this phone (signed off, or never registered):
        // the full registration instead.
        if (!updated) await _register(token, languageCode);
        return Unit.instance;
      });

  @override
  FutureResult<Unit> unregisterDevice() => guard(() async {
    await _remote.unregister(_local.deviceId());
    return Unit.instance;
  });

  @override
  FutureResult<Unit> deleteToken() => guard(() async {
    await _messaging.deleteToken();
    return Unit.instance;
  });

  Future<String> _token() async {
    final token = await _messaging.getToken();
    if (token == null) {
      // iOS without an APNs token: usually a simulator, or the Push
      // Notifications capability missing from the signing profile.
      throw const Failure.unknown(message: 'No FCM token available');
    }
    // For testers to paste into the Firebase console's test message.
    // Debug builds only: never in a release log.
    if (kDebugMode) debugPrint('[Push] FCM token: $token');
    return token;
  }

  Future<void> _register(String token, String languageCode) =>
      _remote.register(
        DeviceRegistrationModel.forPhone(
          deviceId: _local.deviceId(),
          deviceToken: token,
          isIOS: Platform.isIOS,
          rawOsVersion: Platform.operatingSystemVersion,
          appVersion: AppConstants.appVersion,
          languageCode: languageCode,
        ),
      );

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
