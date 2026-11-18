import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/notifications/data/models/notification_model.dart';
import 'package:next_on/features/notifications/domain/entities/app_notification.dart';

/// A row of `GET /mobile/notifications` (#54), read defensively.
void main() {
  Map<String, dynamic> row([Map<String, dynamic> changes = const {}]) => {
    'id': 'n-1',
    'notification_type': 'leave_request',
    'title': 'Leave approved',
    'body': 'Your leave was approved',
    'data': {
      'reference_type': 'leave_request',
      'reference_id': 'lr-1',
      'notification_type': 'leave_request',
    },
    'status': 'sent',
    'sent_at': '2026-11-18T02:00:05Z',
    'created_at': '2026-11-18T02:00:00Z',
    ...changes,
  };

  test('every field', () {
    final n = NotificationModel.fromJson(row())!;
    expect(n.id, 'n-1');
    expect(n.type, 'leave_request');
    expect(n.title, 'Leave approved');
    expect(n.body, 'Your leave was approved');
    expect(n.data['reference_id'], 'lr-1');
    expect(n.status, NotificationSendStatus.sent);
    expect(n.sentAt, DateTime.utc(2026, 11, 18, 2, 0, 5));
    expect(n.createdAt, DateTime.utc(2026, 11, 18, 2));
  });

  test('null data: no data, the row still listed', () {
    final n = NotificationModel.fromJson(row({'data': null}))!;
    expect(n.data, isEmpty);
    expect(n.routeData, {'notification_type': 'leave_request'});
  });

  test('data with values that are not text: read as text', () {
    final n = NotificationModel.fromJson(
      row({
        'data': {'reference_id': 42, 'flag': true, 'gone': null},
      }),
    )!;
    expect(n.data, {'reference_id': '42', 'flag': 'true'});
  });

  test('data that is not an object: no data', () {
    expect(NotificationModel.fromJson(row({'data': 'x'}))!.data, isEmpty);
  });

  test('no sent_at (pending, or failed): still listed', () {
    final n = NotificationModel.fromJson(
      row({'sent_at': null, 'status': 'failed'}),
    )!;
    expect(n.sentAt, isNull);
    expect(n.status, NotificationSendStatus.failed);
  });

  test('an unknown type and status are kept', () {
    final n = NotificationModel.fromJson(
      row({'notification_type': 'payslip_ready', 'status': 'queued'}),
    )!;
    expect(n.type, 'payslip_ready');
    expect(n.status, NotificationSendStatus.unknown);
  });

  test('the type is the top-level one, never data\'s', () {
    final n = NotificationModel.fromJson(
      row({
        'notification_type': 'overtime_request',
        'data': {
          'reference_type': 'overtime_announcement',
          'notification_type': 'something_else',
        },
      }),
    )!;
    expect(n.type, 'overtime_request');
    expect(n.routeData['notification_type'], 'overtime_request');
  });

  test('no top-level type: the data\'s own is kept for the tap', () {
    final n = NotificationModel.fromJson(row({'notification_type': null}))!;
    expect(n.type, isEmpty);
    expect(n.routeData['notification_type'], 'leave_request');
    expect(n.target, isNotNull);
  });

  test('no id or no readable created_at: cannot be listed', () {
    expect(NotificationModel.fromJson(row({'id': null})), isNull);
    expect(NotificationModel.fromJson(row({'id': ''})), isNull);
    expect(NotificationModel.fromJson(row({'created_at': null})), isNull);
    expect(NotificationModel.fromJson(row({'created_at': 'soon'})), isNull);
  });

  test('missing title and body: empty, not "null"', () {
    final n = NotificationModel.fromJson(row({'title': null, 'body': null}))!;
    expect(n.title, isEmpty);
    expect(n.body, isEmpty);
  });
}
