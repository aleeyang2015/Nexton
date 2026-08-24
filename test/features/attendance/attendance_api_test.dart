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

  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastBody = options.data == null ? null : jsonEncode(options.data);

    return ResponseBody.fromString(
      jsonEncode(body),
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

  group('today record', () {
    test('reads sessions and reports an open one as clocked in', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'date': '2026-08-24',
              'status': 'present',
              'sessions': [
                {
                  'session_label': '08:00–12:00',
                  'clock_in': '2026-08-24T01:05:00Z',
                  'clock_out': '2026-08-24T05:00:00Z',
                  'is_late': false,
                },
                {
                  'session_label': '13:30–17:30',
                  'clock_in': '2026-08-24T06:30:00Z',
                  'is_late': true,
                },
              ],
            },
          ],
        };

      final day = await source.todayRecord();

      expect(day.sessions, hasLength(2));
      expect(day.isClockedIn, isTrue);
      expect(day.nextAction, ClockAction.clockOut);
      expect(day.openSession?.label, '13:30–17:30');
      expect(day.firstClockIn!.toUtc(), DateTime.utc(2026, 8, 24, 1, 5));
      expect(day.lastClockOut!.toUtc(), DateTime.utc(2026, 8, 24, 5));
    });

    test('a day with no records is empty, not a failure', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      final day = await source.todayRecord();

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
              'sessions': [
                {
                  'clock_in': '2026-08-24T01:05:00Z',
                  'clock_out': '2026-08-24T10:00:00Z',
                },
              ],
            },
          ],
        };

      final day = await source.todayRecord();

      expect(day.isClockedIn, isFalse);
      expect(day.nextAction, ClockAction.clockIn);
    });

    test('queries a single local date', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await source.todayRecord();

      final query = adapter.lastRequest!.queryParameters;
      expect(query['start_date'], query['end_date']);
      // ASCII digits, never the active locale's numerals.
      expect(query['start_date'], matches(r'^\d{4}-\d{2}-\d{2}$'));
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
