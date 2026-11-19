import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/device_local_data_source.dart';
import 'data/datasources/device_remote_data_source.dart';
import 'data/datasources/firebase_messaging_data_source.dart';
import 'data/datasources/local_notification_data_source.dart';
import 'data/datasources/notifications_remote_data_source.dart';
import 'data/repositories/notifications_repository_impl.dart';
import 'data/repositories/push_notification_repository_impl.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/repositories/push_notification_repository.dart';
import 'domain/usecases/get_notifications_usecase.dart';
import 'domain/usecases/get_unread_count_usecase.dart';
import 'domain/usecases/mark_all_notifications_read_usecase.dart';
import 'domain/usecases/mark_notification_read_usecase.dart';
import 'domain/usecases/register_device_usecase.dart';

// Composition root for the notifications feature: the one place the data
// layer is constructed and bound to the domain contracts.

/// Whether Firebase started (`AppInitializer.initialize`, set in
/// `main.dart`). False by default: a test or a phone where it failed gets
/// no push, never a crash (#51).
final pushAvailableProvider = Provider<bool>((ref) => false);

final firebaseMessagingDataSourceProvider =
    Provider<FirebaseMessagingDataSource>(
      (ref) => FirebaseMessagingDataSourceImpl.instance(),
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

/// The bell list's rows (#54).
final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => NotificationsRemoteDataSourceImpl(ref.watch(apiClientProvider)),
    );

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>(
  (ref) => GetNotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>(
      (ref) => MarkNotificationReadUseCase(
        ref.watch(notificationsRepositoryProvider),
      ),
    );

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>(
      (ref) => MarkAllNotificationsReadUseCase(
        ref.watch(notificationsRepositoryProvider),
      ),
    );

final getUnreadCountUseCaseProvider = Provider<GetUnreadCountUseCase>(
  (ref) => GetUnreadCountUseCase(ref.watch(notificationsRepositoryProvider)),
);

/// A tick for each push that arrives while the App is open (#55: the bell's
/// count is read again). Nothing when Firebase did not start (#51).
final foregroundPushesProvider = Provider<Stream<void>>(
  (ref) => ref.watch(pushAvailableProvider)
      ? ref.watch(pushNotificationRepositoryProvider).onForegroundMessage
      : const Stream<void>.empty(),
);
