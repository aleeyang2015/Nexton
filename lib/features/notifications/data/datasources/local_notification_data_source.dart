import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/push_message.dart';
import 'push_constants.dart';

/// Shows a banner for a push that arrived while the app is open. Android
/// only: FCM puts nothing on screen there for a foreground push, while iOS
/// does it itself. The banner carries the push's `data`, so a tap on it
/// opens the same place as a tap on the push itself (#53).
abstract class LocalNotificationDataSource {
  Future<void> show(PushMessage message);

  /// The `data` of a banner tapped while the App runs.
  Stream<Map<String, String>> get onTap;

  /// The `data` of the banner whose tap started the App, if any.
  Future<Map<String, String>?> launchTap();
}

/// A banner's payload: the push `data` as JSON. Anything unreadable is no
/// data at all.
abstract final class BannerPayload {
  static String encode(Map<String, dynamic> data) =>
      jsonEncode({for (final e in data.entries) e.key: '${e.value}'});

  static Map<String, String>? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return {
        for (final e in decoded.entries)
          if (e.value != null) '${e.key}': '${e.value}',
      };
    } catch (_) {
      return null;
    }
  }
}

class LocalNotificationDataSourceImpl implements LocalNotificationDataSource {
  static const _channel = AndroidNotificationChannel(
    PushConstants.androidChannelId,
    PushConstants.androidChannelName,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;
  final _taps = StreamController<Map<String, String>>.broadcast();

  LocalNotificationDataSourceImpl(this._plugin);

  /// Sets the plugin up and creates the channel on first use only.
  Future<void> _ensureReady() => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(PushConstants.androidSmallIcon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final data = BannerPayload.decode(response.payload);
        if (data != null) _taps.add(data);
      },
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
      payload: BannerPayload.encode(message.data),
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

  @override
  Stream<Map<String, String>> get onTap => _taps.stream;

  @override
  Future<Map<String, String>?> launchTap() async {
    // Set up now: the tap callback is registered by `initialize`.
    await _ensureReady();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return BannerPayload.decode(details.notificationResponse?.payload);
  }
}
