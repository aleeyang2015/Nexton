import '../../domain/entities/app_notification.dart';

/// Reads one row of `GET /mobile/notifications` (#54), defensively: `data`
/// may be null or hold non-text values, `sent_at` may be missing, and a
/// value this App does not know is kept, not refused. A row with no id or
/// no readable `created_at` cannot be listed: null, and the page skips it.
abstract final class NotificationModel {
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final createdAt = _time(json['created_at']);
    if (id.isEmpty || createdAt == null) return null;
    final raw = json['data'];
    return AppNotification(
      id: id,
      type: _text(json['notification_type']),
      title: _text(json['title']),
      body: _text(json['body']),
      data: raw is Map
          ? {
              for (final e in raw.entries)
                if (e.value != null) '${e.key}': '${e.value}',
            }
          : const {},
      status: NotificationSendStatus.fromWire(json['status']),
      sentAt: _time(json['sent_at']),
      createdAt: createdAt,
    );
  }

  static String _text(Object? value) => value == null ? '' : '$value'.trim();

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
