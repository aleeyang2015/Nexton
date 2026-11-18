import 'dart:async';
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

  /// A token delete still on its way (sign-out): the next registration
  /// waits for it, or it would register the token being killed.
  Future<void>? _deleting;

  /// The last delete failed (no signal: Firebase needs the network): the
  /// next registration tries it again first, so the old token dies then.
  bool _deleteOwed = false;

  @override
  FutureResult<Unit> deleteToken() => guard(() async {
    final deleting = _messaging.deleteToken();
    _deleting = deleting;
    try {
      await deleting;
      _deleteOwed = false;
    } catch (_) {
      _deleteOwed = true;
      rethrow;
    } finally {
      if (identical(_deleting, deleting)) _deleting = null;
    }
    return Unit.instance;
  });

  Future<String> _token() async {
    final deleting = _deleting;
    if (deleting != null) {
      try {
        await deleting;
      } catch (_) {
        // Owed: tried again just below.
      }
    }
    if (_deleteOwed) {
      try {
        await _messaging.deleteToken();
        _deleteOwed = false;
      } catch (_) {
        // Still no signal: the old token is sent; the server's shared-phone
        // rule moves it to whoever signs in now.
      }
    }
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

  Future<void> _register(String token, String languageCode) => _remote.register(
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

  @override
  Stream<Map<String, String>> get openedPushes {
    // Both sources as one stream, without a package for it.
    late final StreamController<Map<String, String>> out;
    final subs = <StreamSubscription<Object?>>[];
    out = StreamController<Map<String, String>>(
      onListen: () {
        subs
          ..add(
            _messaging.onMessageOpenedApp.listen(
              (m) => out.add(_stringData(m.data)),
              onError: (_) {},
            ),
          )
          ..add(_localNotifications.onTap.listen(out.add, onError: (_) {}));
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return out.stream;
  }

  @override
  FutureResult<Map<String, String>?> launchPush() => guard(() async {
    final message = await _messaging.initialMessage();
    if (message != null) return _stringData(message.data);
    return _localNotifications.launchTap();
  });

  static Map<String, String> _stringData(Map<String, dynamic> data) => {
    for (final e in data.entries)
      if (e.value != null) e.key: '${e.value}',
  };
}
