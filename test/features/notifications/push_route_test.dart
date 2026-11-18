import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/features/notifications/data/datasources/local_notification_data_source.dart';
import 'package:next_on/features/notifications/domain/push_route.dart';
import 'package:next_on/features/notifications/presentation/push_router.dart';

/// Where a tapped push opens (#53): one case per row of the issue's table,
/// routed on the pair (`notification_type`, `reference_type`).
void main() {
  Map<String, String> push(String type, String reference, [String? id]) => {
    'notification_type': type,
    'reference_type': reference,
    'reference_id': ?id,
  };

  final rows = <(String, Map<String, String>, PushTarget, String)>[
    (
      'leave asked / approved / rejected',
      push('leave_request', 'leave_request', 'lr-1'),
      const LeaveRequestTarget('lr-1'),
      '/time-off/request/lr-1',
    ),
    (
      '"forgot to scan" asked / approved / rejected',
      push('attendance_correction', 'attendance_correction', 'tc-1'),
      const CorrectionTarget('tc-1'),
      '/attendance/requests/correction/tc-1',
    ),
    (
      'a clock-in refused outside every area: Home (no id)',
      {
        'notification_type': 'attendance_offsite',
        'reference_type': 'attendance',
        'reason': 'outside',
        'log_type': 'in',
      },
      const HomeTarget(),
      '/',
    ),
    (
      'HR posts OT: the posts page (staff cannot read one by id)',
      push('overtime_announcement', 'overtime_announcement', 'post-1'),
      const OtPostsTarget(),
      '/overtime/posts',
    ),
    (
      'HR cancels a post: type overtime_request, but my OT list',
      push('overtime_request', 'overtime_announcement', 'post-1'),
      const MyOtTarget(),
      '/overtime',
    ),
    (
      'OT joined / asked / approved / rejected / cancelled',
      push('overtime_request', 'overtime_request', 'ot-1'),
      const OtRequestTarget('ot-1'),
      '/overtime/request/ot-1',
    ),
  ];

  for (final (label, data, target, location) in rows) {
    test(label, () {
      expect(pushTarget(data), target);
      expect(PushRouter.locationOf(pushTarget(data)), location);
    });
  }

  test('the OT request location is the route helper\'s', () {
    expect(AppRoutes.otRequest('ot-1'), '/overtime/request/ot-1');
  });

  group('anything else: Home', () {
    for (final (label, data) in <(String, Map<String, Object?>)>[
      ('an unknown type', push('payslip_ready', 'payslip', 'p-1')),
      ('no data at all', const {}),
      ('a leave push with no id', push('leave_request', 'leave_request')),
      (
        'a leave push with an empty id',
        push('leave_request', 'leave_request', '  '),
      ),
      ('an OT push with no id', push('overtime_request', 'overtime_request')),
      (
        'a correction push with no id',
        push('attendance_correction', 'attendance_correction'),
      ),
      (
        'a known type with a reference it never sends',
        push('leave_request', 'overtime_request', 'x'),
      ),
    ]) {
      test(label, () => expect(pushTarget(data), const HomeTarget()));
    }
  });

  test('an id is used as sent, made safe in the location', () {
    final target = pushTarget(push('leave_request', 'leave_request', 'a/b c'));
    expect(target, const LeaveRequestTarget('a/b c'));
    expect(PushRouter.locationOf(target), '/time-off/request/a%2Fb%20c');
  });

  group('the Android banner carries the push data', () {
    test('round trip', () {
      final data = push('leave_request', 'leave_request', 'lr-1');
      expect(BannerPayload.decode(BannerPayload.encode(data)), data);
    });

    test('unreadable payloads are no data', () {
      expect(BannerPayload.decode(null), isNull);
      expect(BannerPayload.decode(''), isNull);
      expect(BannerPayload.decode('not json'), isNull);
      expect(BannerPayload.decode('[1, 2]'), isNull);
    });
  });
}
