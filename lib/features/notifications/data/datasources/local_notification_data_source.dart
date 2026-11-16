import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/push_message.dart';
import 'push_constants.dart';

/// Shows a banner for a push that arrived while the app is open. Android
/// only: FCM puts nothing on screen there for a foreground push, while iOS
/// does it itself.
abstract class LocalNotificationDataSource {
  Future<void> show(PushMessage message);
}

class LocalNotificationDataSourceImpl implements LocalNotificationDataSource {
  static const _channel = AndroidNotificationChannel(
    PushConstants.androidChannelId,
    PushConstants.androidChannelName,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  LocalNotificationDataSourceImpl(this._plugin);

  /// Sets the plugin up and creates the channel on first use only.
  Future<void> _ensureReady() => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }();

  @override
  Future<void> show(PushMessage message) async {
    await _ensureReady();
    await _plugin.show(
      // Unique enough to keep several banners from replacing each other.
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
