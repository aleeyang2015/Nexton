import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_receipt.dart';
import 'package:next_on/features/attendance/domain/entities/punch_request.dart';

/// Serves one canned response and records the request that asked for it.
class _StubAdapter implements HttpClientAdapter {
  /// Set per-case before the call under test.
  int status = 200;
  Object body = const <String, dynamic>{};

  /// When set, answers each request from its own query instead of [body] —
  /// for calls that go out in parallel to different months.
  Object Function(RequestOptions options)? bodyFor;

  RequestOptions? lastRequest;
  String? lastBody;

  /// Every request seen, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requests.add(options);
    lastBody = options.data == null ? null : jsonEncode(options.data);

    return ResponseBody.fromString(
      jsonEncode(bodyFor?.call(options) ?? body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _StubAdapter adapter;
  late AttendanceRemoteDataSourceImpl source;

  setUp(() {
    adapter = _StubAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    source = AttendanceRemoteDataSourceImpl(ApiClient(dio: dio));
  });

  const gpsRequest = PunchRequest(
    method: ClockMethod.gps,
    reading: PunchLocationReadingStub.office,
  );

  group('clock-in', () {
    test('a verified punch comes back recorded and verified', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'checkin_id': 'uuid-1',
            'status': 'verified',
            'message': 'Clock-in successful',
            'location_name': 'สำนักงานใหญ่',
            'distance_from_center': 23.4,
            'timestamp': '2026-08-24T01:15:00Z',
            'is_late': false,
            'late_minutes': 0,
            'session_order': 0,
            'session_label': '08:00–12:00',
          },
        };

      final outcome = await source.clockIn(gpsRequest);

      expect(outcome, isA<PunchRecorded>());
      final receipt = (outcome as PunchRecorded).receipt;
      expect(receipt.isVerified, isTrue);
      expect(receipt.sessionLabel, '08:00–12:00');
      expect(receipt.locationName, 'สำนักงานใหญ่');
      // UTC in, local out — §7 rule 9.
      expect(receipt.timestamp.isUtc, isFalse);
      expect(receipt.timestamp.toUtc(), DateTime.utc(2026, 8, 24, 1, 15));
    });

    test('a 200 carrying status=rejected is stored but not verified', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'checkin_id': 'uuid-2',
            'status': 'rejected',
            'message': 'Outside the office',
            'rejection_reason': 'outside_geofence',
            'timestamp': '2026-08-24T01:15:00Z',
          },
        };

      final outcome = await source.clockIn(gpsRequest);

      final receipt = (outcome as PunchRecorded).receipt;
      // The loudest warning in §3: a 200 does not mean the punch counted.
      expect(receipt.isVerified, isFalse);
      expect(receipt.needsWarning, isTrue);
      expect(receipt.rejectionReason, PunchRejectionReason.outsideGeofence);
    });

    test(
      'an unrecognised status is treated as pending, never verified',
      () async {
        adapter
          ..status = 200
          ..body = {
            'success': true,
            'data': {
              'checkin_id': 'uuid-3',
              'status': 'something_new',
              'timestamp': '2026-08-24T01:15:00Z',
            },
          };

        final receipt =
            ((await source.clockIn(gpsRequest)) as PunchRecorded).receipt;

        expect(receipt.verification, PunchVerification.pending);
        expect(receipt.isVerified, isFalse);
      },
    );

    test('sends the documented field names', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'checkin_id': 'x',
            'status': 'verified',
            'timestamp': '2026-08-24T01:15:00Z',
          },
        };

      await source.clockIn(gpsRequest);

      final sent = jsonDecode(adapter.lastBody!) as Map<String, dynamic>;
      expect(sent['method'], 'gps');
      expect(sent['latitude'], 17.9757);
      expect(sent['longitude'], 102.6331);
      expect(sent['gps_accuracy'], 12.5);
      expect(sent['is_mock_location'], isFalse);
      expect(adapter.lastRequest!.path, contains('/attendance/clock-in'));
    });

    test(
      'omits is_mock_location when the device could not be checked',
      () async {
        adapter
          ..status = 200
          ..body = {
            'success': true,
            'data': {
              'checkin_id': 'x',
              'status': 'verified',
              'timestamp': '2026-08-24T01:15:00Z',
            },
          };

        await source.clockIn(
          const PunchRequest(
            method: ClockMethod.gps,
            reading: PunchLocationReading(latitude: 1, longitude: 2),
          ),
        );

        final sent = jsonDecode(adapter.lastBody!) as Map<String, dynamic>;
        // Never assert `false` for something the app did not verify.
        expect(sent.containsKey('is_mock_location'), isFalse);
      },
    );
  });

  group('business refusals', () {
    test(
      'EARLY_CHECKOUT_REQUIRES_REASON blocks and keeps its details',
      () async {
        adapter
          ..status = 409
          ..body = {
            'success': false,
            'error': {
              'code': 'EARLY_CHECKOUT_REQUIRES_REASON',
              'message': 'จะออกก่อน 17:30 ต้องกรอกเหตุผล',
              'details': {
                'session_label': '13:30–17:30',
                'earliest_checkout': '17:20',
              },
            },
          };

        final outcome = await source.clockOut(gpsRequest);

        expect(outcome, isA<PunchBlocked>());
        final blocked = outcome as PunchBlocked;
        expect(blocked.rule, AttendanceRule.earlyCheckoutRequiresReason);
        expect(blocked.rule.isResolvableWithReason, isTrue);
        expect(blocked.details.earliestCheckout, '17:20');
        expect(blocked.details.sessionLabel, '13:30–17:30');
        expect(blocked.message, 'จะออกก่อน 17:30 ต้องกรอกเหตุผล');
      },
    );

    test('TOO_EARLY_CHECKIN on a punch blocks and says when clock-in opens',
        () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'TOO_EARLY_CHECKIN',
            'message':
                'Too early to clock in for the 08:00–12:00 session; '
                'clock-in opens at 07:00.',
            'details': {
              'session_label': '08:00–12:00',
              'session_order': 0,
              'clock_in_opens': '07:00',
            },
          },
        };

      final blocked = await source.clockIn(gpsRequest) as PunchBlocked;

      expect(blocked.rule, AttendanceRule.tooEarlyCheckin);
      expect(blocked.rule.isResolvableWithReason, isFalse);
      expect(blocked.details.clockInOpens, '07:00');
      expect(blocked.details.sessionLabel, '08:00–12:00');
    });

    test('CLOCK_OUT_BEFORE_CLOCK_IN blocks and says when the clock-in was',
        () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'CLOCK_OUT_BEFORE_CLOCK_IN',
            'message': 'Clock-out time is before clock-in',
            'details': {
              'session_label': '08:00–12:00',
              'session_order': 0,
              'clock_in': '08:05',
            },
          },
        };

      final blocked = await source.clockOut(gpsRequest) as PunchBlocked;

      expect(blocked.rule, AttendanceRule.clockOutBeforeClockIn);
      // No reason clears it, so the reason dialog must never open.
      expect(blocked.rule.isResolvableWithReason, isFalse);
      expect(blocked.rule.isResolvableOffsite, isFalse);
      expect(blocked.details.clockIn, '08:05');
    });

    test('OT_CHANGED blocks on a clock-in and on a clock-out', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'OT_CHANGED', 'message': 'OT changed, retry'},
        };

      final onIn = await source.clockIn(gpsRequest) as PunchBlocked;
      final onOut = await source.clockOut(gpsRequest) as PunchBlocked;

      expect(onIn.rule, AttendanceRule.otChanged);
      expect(onOut.rule, AttendanceRule.otChanged);
      expect(onIn.details, PunchBlockDetails.empty);
    });

    test('a 409 with a code the App does not know is not a rule', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'SHIFT_LOCKED', 'message': 'locked'},
        };

      await expectLater(
        source.clockIn(gpsRequest),
        throwsA(isA<DioException>()),
      );
    });

    test(
      '403 MOCK_LOCATION_DETECTED is a rule, not a transport error',
      () async {
        adapter
          ..status = 403
          ..body = {
            'success': false,
            'error': {'code': 'MOCK_LOCATION_DETECTED', 'message': 'fake gps'},
          };

        final outcome = await source.clockIn(gpsRequest);

        expect(
          (outcome as PunchBlocked).rule,
          AttendanceRule.mockLocationDetected,
        );
      },
    );

    test(
      'OUTSIDE_GEOFENCE is the rule that offers the off-site request',
      () async {
        // The deployed API's actual answer, verbatim: no `data`, so nothing
        // was stored, and `outside_geofence` arrives as an error code rather
        // than the receipt field §3 documents.
        adapter
          ..status = 409
          ..body = {
            'success': false,
            'error': {
              'code': 'OUTSIDE_GEOFENCE',
              'message':
                  'Clock-in rejected: you are outside all work locations',
            },
          };

        final outcome = await source.clockIn(gpsRequest);

        expect(outcome, isA<PunchBlocked>());
        final blocked = outcome as PunchBlocked;
        expect(blocked.rule, AttendanceRule.outsideWorkArea);
        expect(blocked.rule.isResolvableOffsite, isTrue);
        // No reason dialog: being in the wrong place is not fixed by typing.
        expect(blocked.rule.isResolvableWithReason, isFalse);
        expect(
          blocked.message,
          'Clock-in rejected: you are outside all work locations',
        );
        // The refusal carries no details, so nothing is invented from them.
        expect(blocked.details, PunchBlockDetails.empty);
      },
    );

    test('CHECKIN_PENDING_APPROVAL on a clock-out (an off-site check-in still '
        'waits): its own rule, not an unknown error (#40)', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'CHECKIN_PENDING_APPROVAL',
            'message': 'Check-in pending approval',
          },
        };

      final outcome = await source.clockOut(gpsRequest);

      expect(
        (outcome as PunchBlocked).rule,
        AttendanceRule.checkinPendingApproval,
      );
    });

    test(
      'an unknown 409 code stays an error rather than a made-up rule',
      () async {
        adapter
          ..status = 409
          ..body = {
            'success': false,
            'error': {'code': 'SOMETHING_NEW', 'message': 'nope'},
          };

        await expectLater(
          source.clockIn(gpsRequest),
          throwsA(isA<DioException>()),
        );
      },
    );

    test('a 401 is left for the session machinery', () async {
      adapter
        ..status = 401
        ..body = {
          'success': false,
          'error': {'code': 'UNAUTHORIZED', 'message': 'expired'},
        };

      await expectLater(
        source.clockIn(gpsRequest),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('open OT session', () {
    test('GET /core_hr/attendance/ot-sessions/open', () async {
      adapter.body = {'success': true, 'data': null};

      await source.openOtSession();

      expect(adapter.lastRequest!.method, 'GET');
      expect(
        adapter.lastRequest!.path,
        '/core_hr/attendance/ot-sessions/open',
      );
    });

    test('"data": null is no open session, not the envelope', () async {
      adapter.body = {'success': true, 'data': null};

      expect(await source.openOtSession(), isNull);
    });

    test('no data at all is no open session too', () async {
      adapter.body = {'success': true};

      expect(await source.openOtSession(), isNull);
    });

    test('reads the request id, the label and both times, on the phone\'s '
        'clock', () async {
      adapter.body = {
        'success': true,
        'data': {
          'overtime_request_id': 'ot-1',
          'session_label': 'OT 19:00–22:00',
          'clock_in': '2026-11-14T18:45:00+07:00',
          'clock_out_until': '2026-11-14T23:00:00+07:00',
        },
      };

      final session = (await source.openOtSession())!;

      expect(session.overtimeRequestId, 'ot-1');
      expect(session.sessionLabel, 'OT 19:00–22:00');
      expect(session.clockIn!.isUtc, isFalse);
      expect(session.clockIn!.toUtc(), DateTime.utc(2026, 11, 14, 11, 45));
      expect(session.clockOutUntil!.toUtc(), DateTime.utc(2026, 11, 14, 16));
    });

    test('a body with no request id is no session', () async {
      adapter.body = {
        'success': true,
        'data': {'session_label': 'OT 19:00–22:00'},
      };

      expect(await source.openOtSession(), isNull);
    });
  });

  group('clock answer on an OT', () {
    test('overtime_request_id and the session label are read', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'checkin_id': 'uuid-ot',
            'status': 'verified',
            'message': 'Clock-in successful',
            'timestamp': '2026-11-14T11:45:00Z',
            'overtime_request_id': 'ot-1',
            'session_label': 'OT 19:00–22:00',
          },
        };

      final outcome = await source.clockIn(gpsRequest);

      final receipt = (outcome as PunchRecorded).receipt;
      expect(receipt.overtimeRequestId, 'ot-1');
      expect(receipt.sessionLabel, 'OT 19:00–22:00');
    });

    test('a shift punch has no OT request id', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': {
            'checkin_id': 'uuid-1',
            'status': 'verified',
            'message': 'ok',
            'timestamp': '2026-08-24T01:15:00Z',
          },
        };

      final outcome = await source.clockIn(gpsRequest);

      expect((outcome as PunchRecorded).receipt.overtimeRequestId, isNull);
    });
  });

  group('today record', () {
    /// A Monday in the middle of a month, mid-morning.
    final monday = DateTime(2026, 11, 16, 10);

    /// A source that believes it is [now].
    AttendanceRemoteDataSourceImpl sourceAt(DateTime now) {
      final dio = Dio()..httpClientAdapter = adapter;
      return AttendanceRemoteDataSourceImpl(ApiClient(dio: dio), now: () => now);
    }

    List<String> monthsAsked() => [
      for (final request in adapter.requests)
        request.queryParameters['month'] as String,
    ];

    test('reads sessions and reports an open one as clocked in', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-11-16',
              'status': 'present',
              'sessions': [
                {
                  'shift_detail': {'start_time': '08:00', 'end_time': '12:00'},
                  'clock_in': '2026-11-16T01:05:00Z',
                  'clock_out': '2026-11-16T05:00:00Z',
                  'is_late': false,
                },
                {
                  'shift_detail': {'start_time': '13:30', 'end_time': '17:30'},
                  'clock_in': '2026-11-16T06:30:00Z',
                  'is_late': true,
                },
              ],
            },
          ],
        };

      final day = await sourceAt(monday).todayRecord();

      expect(day.sessions, hasLength(2));
      expect(day.isClockedIn, isTrue);
      expect(day.nextAction, ClockAction.clockOut);
      expect(day.openSession?.partStartTime, '13:30');
      expect(day.firstClockIn!.toUtc(), DateTime.utc(2026, 11, 16, 1, 5));
      expect(day.lastClockOut!.toUtc(), DateTime.utc(2026, 11, 16, 5));
    });

    test('mid-month it asks for one month, five rows, in ASCII digits and '
        'with no date range', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await sourceAt(monday).todayRecord();

      expect(monthsAsked(), ['2026-11']);
      final query = adapter.requests.single.queryParameters;
      expect(query['per_page'], 5);
      expect(query['page'], 1);
      expect(query.containsKey('start_date'), isFalse);
      expect(query.containsKey('end_date'), isFalse);
      // ASCII digits, never the active locale's numerals.
      expect(query['month'], matches(r'^\d{4}-\d{2}$'));
    });

    test('on 1 December it also asks for November: yesterday is there',
        () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await sourceAt(DateTime(2026, 12, 1, 2)).todayRecord();

      expect(monthsAsked(), unorderedEquals(['2026-12', '2026-11']));
    });

    test('on 30 November it also asks for December: tomorrow is there',
        () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await sourceAt(DateTime(2026, 11, 30, 23, 55)).todayRecord();

      expect(monthsAsked(), unorderedEquals(['2026-11', '2026-12']));
    });

    test('on 31 December and 1 January the year turns with the month',
        () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await sourceAt(DateTime(2026, 12, 31, 12)).todayRecord();
      expect(monthsAsked(), unorderedEquals(['2026-12', '2027-01']));

      adapter.requests.clear();
      await sourceAt(DateTime(2027, 1, 1, 12)).todayRecord();
      expect(monthsAsked(), unorderedEquals(['2026-12', '2027-01']));
    });

    test('a night shift opened on the last day of last month is found on '
        'the 1st', () async {
      adapter
        ..status = 200
        ..bodyFor = (options) => {
          'success': true,
          'data': options.queryParameters['month'] == '2026-11'
              ? [
                  {
                    'date': '2026-11-30',
                    'sessions': [
                      {
                        'clock_in': '2026-11-30 23:35:00',
                        'shift_detail': {
                          'start_time': '23:30',
                          'end_time': '07:30',
                        },
                      },
                    ],
                  },
                ]
              : <dynamic>[],
        };

      final day = await sourceAt(DateTime(2026, 12, 1, 2)).todayRecord();

      expect(day.nextAction, ClockAction.clockOut);
      expect(day.openSession?.partStartTime, '23:30');
      expect(day.openSession?.crossesMidnight, isTrue);
    });

    test('a 23:50 punch filed under tomorrow, in the next month, is found',
        () async {
      adapter
        ..status = 200
        ..bodyFor = (options) => {
          'success': true,
          'data': options.queryParameters['month'] == '2026-12'
              ? [
                  {
                    'date': '2026-12-01',
                    'sessions': [
                      {
                        'clock_in': '2026-11-30 23:50:00',
                        'shift_detail': {
                          'start_time': '00:00:00',
                          'end_time': '08:00:00',
                        },
                      },
                    ],
                  },
                ]
              : <dynamic>[],
        };

      final day = await sourceAt(DateTime(2026, 11, 30, 23, 55)).todayRecord();

      expect(day.nextAction, ClockAction.clockOut);
      expect(day.openSession?.partStartTime, '00:00:00');
    });

    test('rows dated after tomorrow do not hide today: the whole month is '
        'read when five rows do not reach back far enough', () async {
      // Five rows the server filed ahead of time fill the short page.
      Map<String, dynamic> ahead(int day) => {
        'date': '2026-11-$day',
        'status': 'leave',
        'sessions': <dynamic>[],
      };
      final today = {
        'date': '2026-11-16',
        'sessions': [
          {
            'shift_detail': {'start_time': '08:00', 'end_time': '17:00'},
            'clock_in': '2026-11-16 08:02:00',
          },
        ],
      };
      adapter
        ..status = 200
        ..bodyFor = (options) => {
          'success': true,
          'data': options.queryParameters['per_page'] == 5
              ? [for (final day in [24, 23, 22, 21, 20]) ahead(day)]
              : [
                  for (final day in [24, 23, 22, 21, 20]) ahead(day),
                  today,
                ],
        };

      final day = await sourceAt(monday).todayRecord();

      expect(day.nextAction, ClockAction.clockOut);
      expect(
        [for (final r in adapter.requests) r.queryParameters['per_page']],
        [5, 100],
      );
    });

    test('a short page that already reaches yesterday is not read twice',
        () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            for (final day in [17, 16, 15, 14, 13])
              {'date': '2026-11-$day', 'sessions': <dynamic>[]},
          ],
        };

      await sourceAt(monday).todayRecord();

      expect(adapter.requests, hasLength(1));
    });

    test('picks today out of the rows of the month', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-11-16',
              'sessions': [
                {
                  'shift_detail': {'start_time': '13:00', 'end_time': '17:00'},
                },
              ],
            },
            {
              'date': '2026-11-13',
              'sessions': [
                {
                  'shift_detail': {'start_time': '08:00', 'end_time': '12:00'},
                },
              ],
            },
          ],
        };

      final day = await sourceAt(monday).todayRecord();

      expect(day.sessions.single.partStartTime, '13:00');
    });

    test('a day shift left open yesterday still offers clock-in', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-11-15',
              'sessions': [
                {
                  'clock_in': '2026-11-15 08:02:00',
                  'shift_detail': {'start_time': '08:00', 'end_time': '17:00'},
                },
              ],
            },
          ],
        };

      final day = await sourceAt(monday).todayRecord();

      expect(day, AttendanceDay.empty);
      expect(day.nextAction, ClockAction.clockIn);
    });

    test('skips a record with no date, since it cannot be placed', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'sessions': [
                {'clock_in': '2026-11-16T01:05:00Z'},
              ],
            },
          ],
        };

      expect(await sourceAt(monday).todayRecord(), AttendanceDay.empty);
    });

    test('a day with no records is empty, not a failure', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      final day = await sourceAt(monday).todayRecord();

      expect(day, AttendanceDay.empty);
      expect(day.nextAction, ClockAction.clockIn);
    });

    test('a fully punched day asks for a clock-in next', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-11-16',
              'sessions': [
                {
                  'clock_in': '2026-11-16T01:05:00Z',
                  'clock_out': '2026-11-16T10:00:00Z',
                },
              ],
            },
          ],
        };

      final day = await sourceAt(monday).todayRecord();

      expect(day.isClockedIn, isFalse);
      expect(day.nextAction, ClockAction.clockIn);
    });

    test('one month failing fails the read: half an answer could offer the '
        'wrong punch', () async {
      adapter.status = 500;
      adapter.body = {
        'success': false,
        'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
      };

      await expectLater(
        sourceAt(DateTime(2026, 12, 1, 2)).todayRecord(),
        throwsA(isA<DioException>()),
      );
    });

    test('without an injected clock it reads the real current month',
        () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await source.todayRecord();

      final now = DateTime.now();
      expect(
        monthsAsked(),
        contains('${now.year}-${now.month.toString().padLeft(2, '0')}'),
      );
    });
  });
}

/// Readings reused across the cases above.
class PunchLocationReadingStub {
  const PunchLocationReadingStub._();

  static const office = PunchLocationReading(
    latitude: 17.9757,
    longitude: 102.6331,
    gpsAccuracy: 12.5,
    isMockLocation: false,
  );
}
