import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/notifications/domain/entities/app_notification.dart';
import 'package:next_on/features/notifications/domain/notification_dedupe.dart';

/// One push, one row (#54): the copy a second phone adds is left out until
/// Nexton-Backend#190.
void main() {
  final at = DateTime.utc(2026, 11, 18, 9);

  AppNotification n(
    String id, {
    Duration after = Duration.zero,
    String title = 'Leave approved',
    Map<String, String> data = const {
      'reference_type': 'leave_request',
      'reference_id': 'lr-1',
    },
  }) => AppNotification(
    id: id,
    type: 'leave_request',
    title: title,
    body: 'Your leave was approved',
    data: data,
    status: NotificationSendStatus.sent,
    // Newest first: a later id is an earlier row.
    createdAt: at.subtract(after),
  );

  List<String> ids(List<AppNotification> rows) => [for (final r in rows) r.id];

  test('a two-phone pair collapses to one', () {
    expect(ids(collapseRepeats([n('a'), n('b', after: seconds(1))])), ['a']);
  });

  test('also when only one copy\'s data has notification_type', () {
    final withType = n(
      'a',
      data: const {
        'reference_type': 'leave_request',
        'reference_id': 'lr-1',
        'notification_type': 'leave_request',
      },
    );
    expect(ids(collapseRepeats([withType, n('b', after: seconds(2))])), ['a']);
  });

  test('three phones: one row', () {
    expect(
      ids(
        collapseRepeats([
          n('a'),
          n('b', after: seconds(1)),
          n('c', after: seconds(2)),
        ]),
      ),
      ['a'],
    );
  });

  test('a run never chains past the window: identical pushes 40 s apart '
      'collapse only into a row within 60 s of them', () {
    expect(
      ids(
        collapseRepeats([
          n('a'),
          n('b', after: seconds(40)),
          n('c', after: seconds(80)),
          n('d', after: seconds(120)),
        ]),
      ),
      ['a', 'c'],
    );
  });

  test('copies interleaved with another push\'s copies collapse too', () {
    AppNotification ot(String id, {Duration after = Duration.zero}) =>
        AppNotification(
          id: id,
          type: 'overtime_announcement',
          title: 'New OT post',
          body: 'b',
          data: const {'reference_type': 'overtime_announcement'},
          status: NotificationSendStatus.sent,
          createdAt: at.subtract(after),
        );
    expect(
      ids(
        collapseRepeats([
          n('a1'),
          ot('b1'),
          n('a2', after: seconds(1)),
          ot('b2', after: seconds(1)),
        ]),
      ),
      ['a1', 'b1'],
    );
  });

  test('two real pushes a minute apart both stay', () {
    expect(ids(collapseRepeats([n('a'), n('b', after: seconds(60))])), [
      'a',
      'b',
    ]);
  });

  test('a different title, or a different request, stays', () {
    expect(ids(collapseRepeats([n('a'), n('b', title: 'Leave rejected')])), [
      'a',
      'b',
    ]);
    expect(
      ids(
        collapseRepeats([
          n('a'),
          n(
            'b',
            data: const {
              'reference_type': 'leave_request',
              'reference_id': 'lr-2',
            },
          ),
        ]),
      ),
      ['a', 'b'],
    );
  });

  test('a copy after another push, within the window, still collapses', () {
    final other = AppNotification(
      id: 'x',
      type: 'overtime_request',
      title: 'OT approved',
      body: 'b',
      data: const {},
      status: NotificationSendStatus.sent,
      createdAt: at,
    );
    expect(ids(collapseRepeats([n('a'), other, n('b')])), ['a', 'x']);
  });

  test('nothing in, nothing out', () {
    expect(collapseRepeats(const []), isEmpty);
  });
}

Duration seconds(int s) => Duration(seconds: s);
