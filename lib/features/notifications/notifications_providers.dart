import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/device_local_data_source.dart';
import 'data/datasources/device_remote_data_source.dart';
import 'data/datasources/firebase_messaging_data_source.dart';
import 'data/datasources/local_notification_data_source.dart';
import 'data/repositories/push_notification_repository_impl.dart';
import 'domain/repositories/push_notification_repository.dart';
import 'domain/usecases/register_device_usecase.dart';

/// Composition root for the notifications feature: the one place the data
/// layer is constructed and bound to the domain contracts.
final firebaseMessagingDataSourceProvider =
    Provider<FirebaseMessagingDataSource>(
      (ref) => FirebaseMessagingDataSourceImpl(FirebaseMessaging.instance),
    );

final localNotificationDataSourceProvider =
    Provider<LocalNotificationDataSource>(
      (ref) =>
          LocalNotificationDataSourceImpl(FlutterLocalNotificationsPlugin()),
    );

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>(
  (ref) => DeviceRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final deviceLocalDataSourceProvider = Provider<DeviceLocalDataSource>(
  (ref) => DeviceLocalDataSourceImpl(ref.watch(sharedPreferencesProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final pushNotificationRepositoryProvider = Provider<PushNotificationRepository>(
  (ref) => PushNotificationRepositoryImpl(
    messaging: ref.watch(firebaseMessagingDataSourceProvider),
    localNotifications: ref.watch(localNotificationDataSourceProvider),
    remote: ref.watch(deviceRemoteDataSourceProvider),
    local: ref.watch(deviceLocalDataSourceProvider),
  ),
);

final registerDeviceUseCaseProvider = Provider<RegisterDeviceUseCase>(
  (ref) => RegisterDeviceUseCase(ref.watch(pushNotificationRepositoryProvider)),
);
