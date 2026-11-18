import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/data/models/time_correction_detail_model.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';

/// A "forgot to scan" request as `GET correction-requests/:id` sends it
/// (#45), and the four calls of "My requests"' correction tab.
void main() {
  Map<String, dynamic> request({
    Object? attendanceRecord,
    List<Map<String, dynamic>>? steps,
    Map<String, dynamic>? employee,
    String? employeeId,
    String status = 'approved',
  }) => {
    'id': 'tc-1',
    'request_date': '2026-11-14',
    'correction_type': 'missing_check_out',
    'requested_clock_out': '17:05',
    'reason': 'Forgot',
    'status': status,
    'created_at': '2026-11-15T02:00:00Z',
    'employee': ?employee,
    'employee_id': ?employeeId,
    'steps': steps ?? const [],
    'attendance_record': ?attendanceRecord,
  };

  group('attendance_record', () {
    test('null until approved: no result', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(status: 'pending'),
      );
      expect(detail.result, isNull);
    });

    test('present: its times as the company wall clock, never shifted', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(
          attendanceRecord: {
            'date': '2026-11-14',
            'clock_in': '2026-11-14 08:02:00',
            'clock_out': '2026-11-14T17:05:00',
            'status': 'late',
            'work_hours': 8.5,
            'is_late': true,
            'late_minutes': 2,
          },
        ),
      );

      final result = detail.result!;
      expect(result.date, DateTime(2026, 11, 14));
      expect(result.clockIn, DateTime(2026, 11, 14, 8, 2));
      expect(result.clockOut, DateTime(2026, 11, 14, 17, 5));
      expect(result.clockOut!.isUtc, isFalse);
      expect(result.status, 'late');
      expect(result.workHours, 8.5);
      expect(result.isLate, isTrue);
      expect(result.lateMinutes, 2);
    });

    test('a zone on the time is not applied: 17:05 stays 17:05', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(
          attendanceRecord: {
            'date': '2026-11-14',
            'clock_in': '2026-11-14T08:00:00Z',
            'clock_out': '2026-11-14T17:05:00+07:00',
          },
        ),
      );

      expect(detail.result!.clockIn, DateTime(2026, 11, 14, 8));
      expect(detail.result!.clockOut, DateTime(2026, 11, 14, 17, 5));
    });

    test('the corrected part (session) gives the times when it is there', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(
          attendanceRecord: {
            'date': '2026-11-14',
            'clock_in': '2026-11-14 08:00:00',
            'clock_out': '2026-11-14 21:00:00',
            'status': 'present',
            'session': {
              'clock_in': '2026-11-14 08:00:00',
              'clock_out': '2026-11-14 12:05:00',
            },
          },
        ),
      );

      expect(detail.result!.clockOut, DateTime(2026, 11, 14, 12, 5));
    });

    test('a bare HH:MM is on the record\'s date', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(attendanceRecord: {'date': '2026-11-14', 'clock_out': '17:05'}),
      );

      expect(detail.result!.clockOut, DateTime(2026, 11, 14, 17, 5));
      expect(detail.result!.clockIn, isNull);
    });

    test('a field of the wrong kind is left out, not a throw', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(
          attendanceRecord: {
            'date': '2026-11-14',
            'work_hours': '8.5',
            'late_minutes': 'two',
            'is_late': 'yes',
          },
        ),
      );

      expect(detail.result!.workHours, isNull);
      expect(detail.result!.lateMinutes, isNull);
      expect(detail.result!.isLate, isFalse);
    });

    test('as a history day it carries the status and the late minutes', () {
      const result = TimeCorrectionResult(status: 'late', lateMinutes: 4);
      final day = result.asDay;
      expect(day.status, 'late');
      expect(day.sessions.single.lateMinutes, 4);
    });
  });

  group('steps', () {
    test('a step with no approver yet reads, with no name', () {
      final detail = TimeCorrectionDetailModel.fromJson(
        request(
          status: 'pending',
          steps: [
            {
              'id': 's-1',
              'step_no': 1,
              'step_role': 'department_head',
              'status': 'pending',
              'approver': null,
            },
          ],
        ),
      );

      final step = detail.steps.single;
      expect(step.approverName, isNull);
      expect(step.status, LeaveStepStatus.pending);
      expect(detail.currentStep, step);
    });
  });

  group('whose request it is', () {
    TimeCorrectionDetail parse({
      Map<String, dynamic>? employee,
      String? employeeId,
      String status = 'pending',
    }) => TimeCorrectionDetailModel.fromJson(
      request(employee: employee, employeeId: employeeId, status: status),
    );

    test('the employee\'s id, from employee.id or employee_id', () {
      expect(parse(employee: {'id': 'e-1', 'name': 'Noy'}).employee.id, 'e-1');
      expect(parse(employeeId: 'e-2').employee.id, 'e-2');
      expect(parse().employee.id, isNull);
    });

    test('Cancel only on the own employee\'s pending request', () {
      final mine = parse(employee: {'id': 'e-1', 'name': 'Noy'});
      expect(mine.canCancelBy('e-1'), isTrue);
      expect(mine.canCancelBy('e-9'), isFalse);

      final decided = parse(
        employee: {'id': 'e-1', 'name': 'Noy'},
        status: 'approved',
      );
      expect(decided.canCancelBy('e-1'), isFalse);
    });

    test('no id on either side: the server decides, so Cancel stays', () {
      expect(parse().canCancelBy('e-1'), isTrue);
      expect(parse(employeeId: 'e-1').canCancelBy(null), isTrue);
    });
  });

  group('the calls', () {
    late _StubAdapter adapter;
    late AttendanceRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      source = AttendanceRemoteDataSourceImpl(ApiClient(dio: dio));
    });

    Map<String, dynamic> row(String id) => {
      'id': id,
      'request_date': '2026-11-14',
      'correction_type': 'missing_check_out',
      'requested_clock_out': '17:05',
      'status': 'pending',
    };

    test('my requests: limit 20, the status and the cursor to the server, '
        'rows in its order', () async {
      adapter.body = {
        'success': true,
        'data': [row('b'), row('a')],
        'meta': {'per_page': 20, 'has_more': true, 'next_cursor': 'c2'},
      };

      final page = await source.myTimeCorrections(
        status: TimeCorrectionStatus.approved,
        cursor: 'c1',
      );

      final query = adapter.lastRequest!.queryParameters;
      expect(adapter.lastRequest!.path, endsWith('correction-requests/my'));
      expect(query['limit'], 20);
      expect(query['status'], 'approved');
      expect(query['cursor'], 'c1');
      expect(query.containsKey('page'), isFalse);
      expect(page.items.map((r) => r.id), ['b', 'a']);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'c2');
    });

    test('all statuses: no status sent; a broken row is dropped', () async {
      adapter.body = {
        'success': true,
        'data': [
          row('a'),
          {'id': 'x'},
        ],
      };

      final page = await source.myTimeCorrections();

      expect(adapter.lastRequest!.queryParameters.containsKey('status'), false);
      expect(adapter.lastRequest!.queryParameters.containsKey('cursor'), false);
      expect(page.items.map((r) => r.id), ['a']);
      expect(page.hasMore, isFalse);
    });

    test('detail 404: "not available" (gone, or not the user\'s)', () async {
      adapter
        ..status = 404
        ..body = {
          'success': false,
          'error': {'code': 'NOT_FOUND', 'message': 'not found'},
        };

      await expectLater(
        source.timeCorrectionDetail('tc-1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            CorrectionErrorCode.tokenRequestGone,
          ),
        ),
      );
    });

    test('cancel CANNOT_CANCEL: "already decided", by its code', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'CANNOT_CANCEL', 'message': 'cannot cancel'},
        };

      await expectLater(
        source.cancelTimeCorrection('tc-1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            CorrectionErrorCode.tokenCannotCancel,
          ),
        ),
      );
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, endsWith('tc-1/cancel'));
    });

    test('another 409 on cancel is not "already decided"', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'SOMETHING_ELSE', 'message': 'no'},
        };

      await expectLater(
        source.cancelTimeCorrection('tc-1'),
        throwsA(isA<DioException>()),
      );
    });

    test('submit answers the new request\'s id; none when it is left '
        'out', () async {
      final sent = TimeCorrectionRequest(
        date: DateTime(2026, 11, 14),
        type: TimeCorrectionType.forgotClockOut,
        shiftDetailId: 'part-1',
        clockIn: null,
        clockOut: const Duration(hours: 17, minutes: 5),
        reason: 'Forgot',
      );

      adapter
        ..status = 201
        ..body = {
          'success': true,
          'data': {'id': 'tc-9', 'status': 'pending'},
        };
      expect(await source.submitTimeCorrection(sent), 'tc-9');

      adapter.body = {'success': true};
      expect(await source.submitTimeCorrection(sent), isNull);
    });
  });
}

/// Serves one canned response and records the request that asked for it.
class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = const <String, dynamic>{};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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
