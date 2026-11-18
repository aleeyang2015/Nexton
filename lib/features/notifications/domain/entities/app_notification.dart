import 'package:equatable/equatable.dart';

import '../push_route.dart';

/// How far the server got sending a push (#54). A `failed` row is still a
/// notification the user should see (the server tried; before
/// Nexton-Backend#187 it fails when it has no Firebase key).
enum NotificationSendStatus {
  pending,
  sent,
  failed,

  /// A value this App does not know yet.
  unknown;

  static NotificationSendStatus fromWire(Object? value) => switch (value) {
    'pending' => pending,
    'sent' => sent,
    'failed' => failed,
    _ => unknown,
  };
}

/// One row of the bell list (#54, `GET /mobile/notifications`): a push sent
/// to the user, as the server logged it.
class AppNotification extends Equatable {
  final String id;

  /// The push's kind (#53's table), from the row's top-level field: inside
  /// [data] it is missing on some rows.
  final String type;

  /// As the server wrote them (English today); never translated here.
  final String title;
  final String body;

  /// The push's `data`, every value as text (`reference_type`,
  /// `reference_id`, …). Empty when the server sent none.
  final Map<String, String> data;

  final NotificationSendStatus status;
  final DateTime? sentAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.status,
    required this.createdAt,
    this.sentAt,
  });

  /// What a tap reads to know where to go (#53's `pushTarget`): the data,
  /// with the row's own type (the data's, when the row's is missing).
  Map<String, String> get routeData => {
    ...data,
    if (type.isNotEmpty) 'notification_type': type,
  };

  /// Where a tap on this row goes (#53), or null when it has nowhere of its
  /// own to go: the bell list it is in.
  PushTarget? get target {
    final target = pushTarget(routeData);
    return target is NotificationsTarget ? null : target;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    data,
    status,
    sentAt,
    createdAt,
  ];
}
