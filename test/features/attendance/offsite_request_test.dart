import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_remote_data_source.dart';
import 'package:next_on/features/attendance/data/models/offsite_detail_model.dart';
import 'package:next_on/features/attendance/data/models/offsite_request_body.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_request.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/core/upload/domain/uploaded_attachment.dart';

/// Serves one canned response and records the request that asked for it —
/// the same stub `attendance_api_test.dart` uses.
class _StubAdapter implements HttpClientAdapter {
  int status = 201;
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
  const photo = UploadedAttachment(
    url: 'https://cdn.nexton.work/uploads/abc.jpg',
    fileName: 'abc.jpg',
    originalName: 'photo.jpg',
    contentType: 'image/jpeg',
    size: 204800,
  );

  OffsiteRequest request({
    OffsiteMethod method = OffsiteMethod.checkOut,
    double? latitude = 17.9757,
    double? longitude = 102.6331,
    String reason = 'Visiting a customer off site',
    UploadedAttachment? attachment = photo,
  }) => OffsiteRequest(
    method: method,
    latitude: latitude,
    longitude: longitude,
    reason: reason,
    attachment: attachment,
  );

  group('OffsiteRequest.violations', () {
    test('a complete request passes', () {
      expect(request().violations(), isEmpty);
      expect(request().validate().isSuccess, isTrue);
    });

    test('needs both ends of the position', () {
      expect(request(latitude: null).violations(), {
        OffsiteFields.location: ValidationCode.locationUnavailable,
      });
      expect(request(longitude: null).violations(), {
        OffsiteFields.location: ValidationCode.locationUnavailable,
      });
    });

    test('needs a non-blank reason within the length limit', () {
      expect(request(reason: '   ').violations(), {
        OffsiteFields.reason: ValidationCode.offsiteReasonRequired,
      });
      expect(request(reason: 'x' * 201).violations(), {
        OffsiteFields.reason: ValidationCode.offsiteReasonTooLong,
      });
    });

    test('needs a photo that carries a url and a file name', () {
      const photoError = {
        OffsiteFields.photo: ValidationCode.offsitePhotoRequired,
      };

      expect(request(attachment: null).violations(), photoError);
      // §3 note 2: the handler re-checks both, so an upload missing either is
      // as good as no photo at all.
      expect(
        request(
          attachment: const UploadedAttachment(
            url: '',
            fileName: 'abc.jpg',
            originalName: 'photo.jpg',
          ),
        ).violations(),
        photoError,
      );
      expect(
        request(
          attachment: const UploadedAttachment(
            url: 'https://cdn.nexton.work/uploads/abc.jpg',
            fileName: '',
            originalName: 'photo.jpg',
          ),
        ).violations(),
        photoError,
      );
    });
  });

  group('OffsiteRequestBody.toJson', () {
    test('matches the documented body', () {
      expect(OffsiteRequestBody(request(reason: '  off site  ')).toJson(), {
        'method': 'check_out',
        'latitude': 17.9757,
        'longitude': 102.6331,
        'reason': 'off site',
        'attachments': {
          'url': 'https://cdn.nexton.work/uploads/abc.jpg',
          'file_name': 'abc.jpg',
          'original_name': 'photo.jpg',
          'content_type': 'image/jpeg',
          'size': 204800,
        },
      });
    });

    test('never sends the employee or the scan time', () {
      final json = OffsiteRequestBody(request()).toJson();
      expect(json.containsKey('employee_id'), isFalse);
      expect(json.containsKey('scan_timestamp'), isFalse);
    });
  });

  group('OffsiteRemoteDataSourceImpl.submit', () {
    late _StubAdapter adapter;
    late OffsiteRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      source = OffsiteRemoteDataSourceImpl(ApiClient(dio: dio));
    });

    test('posts to the documented path', () async {
      adapter.body = {
        'success': true,
        'data': {'id': 'uuid', 'status': 'pending'},
      };

      await source.submit(request());

      expect(adapter.lastRequest?.path, '/core_hr/attendance/offsite-requests');
      expect(adapter.lastRequest?.method, 'POST');
    });

    test('an auto-approved request reports the punch as recorded', () async {
      adapter.body = {
        'success': true,
        'data': {
          'id': 'uuid',
          'status': 'approved',
          'scan_timestamp': '2026-10-02 08:15:00',
          'session_order': 1,
          'attendance_record_id': 'record-1',
        },
      };

      final outcome = await source.submit(request());

      expect(outcome, isA<OffsiteFiled>());
      final filed = (outcome as OffsiteFiled).submission;
      expect(filed.autoApproved, isTrue);
      expect(filed.attendanceRecordId, 'record-1');
      expect(filed.sessionOrder, 1);
      // A wall clock with no timezone stays exactly as sent — never shifted
      // into UTC (§11.4).
      expect(filed.scanTimestamp, DateTime(2026, 10, 2, 8, 15));
    });

    test('a request awaiting HR is filed, not approved', () async {
      adapter.body = {
        'success': true,
        'data': {'id': 'uuid', 'status': 'pending'},
      };

      final outcome = await source.submit(request());

      expect((outcome as OffsiteFiled).submission.autoApproved, isFalse);
    });

    test(
      '409 OFFSITE_REQUEST_EXISTS is a rule, not a transport error',
      () async {
        adapter
          ..status = 409
          ..body = {
            'success': false,
            'error': {
              'code': 'OFFSITE_REQUEST_EXISTS',
              'message': 'A request for this session is already pending.',
              'details': {'session_order': 1, 'method': 'check_out'},
            },
          };

        final outcome = await source.submit(request());

        expect(outcome, isA<OffsiteBlocked>());
        final blocked = outcome as OffsiteBlocked;
        expect(blocked.rule, AttendanceRule.offsiteRequestExists);
        expect(blocked.details.sessionOrder, 1);
        expect(
          blocked.message,
          'A request for this session is already pending.',
        );
      },
    );

    test('409 TOO_EARLY_CHECKIN keeps the opening time', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'TOO_EARLY_CHECKIN',
            'message': '',
            'details': {'session_label': 'morning', 'clock_in_opens': '07:45'},
          },
        };

      final outcome = await source.submit(request());

      final blocked = outcome as OffsiteBlocked;
      expect(blocked.rule, AttendanceRule.tooEarlyCheckin);
      expect(blocked.details.clockInOpens, '07:45');
      expect(blocked.details.sessionLabel, 'morning');
    });

    test('the session rules a punch shares are the punch rules', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'SESSION_ALREADY_STARTED',
            'message': 'Clock out instead.',
          },
        };

      expect(
        ((await source.submit(request())) as OffsiteBlocked).rule,
        AttendanceRule.sessionAlreadyStarted,
      );
    });

    test('409 OT_CHANGED (#110: the OT cancelled as the check-out went) is '
        'the OT-changed rule', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'OT_CHANGED', 'message': 'Please try again.'},
        };

      expect(
        ((await source.submit(request())) as OffsiteBlocked).rule,
        AttendanceRule.otChanged,
      );
    });

    test('which refusals mean today changed: the four SESSION_*, the '
        'pending check-in and a changed OT close the form; the rest keep it',
        () {
      const closes = {
        AttendanceRule.sessionAlreadyStarted,
        AttendanceRule.sessionAlreadyCompleted,
        AttendanceRule.sessionAlreadyCheckedOut,
        AttendanceRule.sessionNotStarted,
        AttendanceRule.checkinPendingApproval,
        AttendanceRule.otChanged,
      };
      for (final rule in AttendanceRule.values) {
        expect(rule.meansTodayChanged, closes.contains(rule), reason: '$rule');
      }
    });

    test('409 CHECKIN_PENDING_APPROVAL is its own rule (#40)', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'CHECKIN_PENDING_APPROVAL',
            'message': 'Check-in pending approval.',
          },
        };

      final blocked = (await source.submit(request())) as OffsiteBlocked;
      expect(blocked.rule, AttendanceRule.checkinPendingApproval);
      expect(blocked.rule.meansTodayChanged, isTrue);
    });

    test('an unknown 409 code stays an error rather than a made-up rule', () {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'SOMETHING_NEW', 'message': 'nope'},
        };

      expect(source.submit(request()), throwsA(isA<DioException>()));
    });

    test('a 422 is left for the repository to map', () {
      adapter
        ..status = 422
        ..body = {
          'success': false,
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Validation failed'},
          'message': 'method is a required field',
          'errors': {
            'method': ['method is a required field'],
          },
        };

      expect(source.submit(request()), throwsA(isA<DioException>()));
    });
  });

  group('OffsiteDetailModel.fromJson', () {
    /// §3's 201 example, which is the same shape the list endpoints answer.
    Map<String, dynamic> json({
      String status = 'pending',
      String method = 'check_in',
      Object? stepStatus = 'pending',
    }) => {
      'id': 'uuid',
      'employee': {
        'id': 'emp-1',
        'name': 'ສົມຊາຍ ໃຈດີ',
        'employee_number': 'EMP-001',
        'department': {'id': 'd1', 'name': 'Sales', 'name_lo': 'ຝ່າຍຂາຍ'},
      },
      'method': method,
      'latitude': 17.9757,
      'longitude': 102.6331,
      'scan_timestamp': '2026-10-02 08:15:00',
      'scan_date': '2026-10-02',
      'session_order': 1,
      'shift_detail': {
        'id': 'sd-1',
        'name': 'Morning',
        'start_time': '08:00',
        'end_time': '12:00',
        'shift': {'id': 's-1', 'name': 'Standard', 'code': 'STD'},
      },
      'attachment': {
        'url': 'https://cdn.nexton.work/uploads/abc.jpg',
        'file_name': 'abc.jpg',
        'original_name': 'photo.jpg',
      },
      'reason': 'Off site with a customer',
      'status': status,
      'current_step_no': 1,
      'attendance_record_id': 'record-1',
      'created_at': '2026-10-02 08:15:00',
      'steps': [
        {
          'id': 'step-1',
          'step_no': 1,
          'step_role': 'hr',
          'approver': null,
          'status': stepStatus,
          'note': null,
          'acted_at': null,
          'created_at': '2026-10-02 08:15:00',
        },
      ],
    };

    test('reads the documented response', () {
      final request = OffsiteDetailModel.fromJson(json());

      expect(request.id, 'uuid');
      expect(request.method, OffsiteMethod.checkIn);
      expect(request.employee.name, 'ສົມຊາຍ ໃຈດີ');
      expect(request.employee.employeeNumber, 'EMP-001');
      expect(request.employee.departmentNameLo, 'ຝ່າຍຂາຍ');
      expect(request.latitude, 17.9757);
      expect(request.longitude, 102.6331);
      // Wall clocks stay as sent (§11.4).
      expect(request.scanTimestamp, DateTime(2026, 10, 2, 8, 15));
      expect(request.scanDate, DateTime(2026, 10, 2));
      expect(request.sessionOrder, 1);
      expect(request.shift?.name, 'Morning');
      expect(request.shift?.shiftCode, 'STD');
      expect(request.attachmentUrl, 'https://cdn.nexton.work/uploads/abc.jpg');
      expect(request.status, TimeCorrectionStatus.pending);
      expect(request.attendanceRecordId, 'record-1');
      expect(request.canCancel, isTrue);
    });

    test('the pending step is the one a decision names', () {
      expect(OffsiteDetailModel.fromJson(json()).currentStep?.id, 'step-1');
      // Nothing is pending once the step has been decided.
      expect(
        OffsiteDetailModel.fromJson(
          json(status: 'approved', stepStatus: 'approved'),
        ).currentStep,
        isNull,
      );
    });

    test("an off-site-only step role falls through to 'unknown'", () {
      final json0 = json()
        ..['steps'] = [
          {
            'id': 's',
            'step_no': 1,
            'step_role': 'specific',
            'status': 'pending',
          },
        ];
      expect(
        OffsiteDetailModel.fromJson(json0).steps.single.role,
        LeaveStepRole.unknown,
      );
    });

    test('a request with no id or method is refused, not shown half-empty', () {
      expect(
        () => OffsiteDetailModel.fromJson(json()..remove('id')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => OffsiteDetailModel.fromJson(json(method: 'sideways')),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OffsiteRemoteDataSourceImpl "My requests" (#42)', () {
    late _StubAdapter adapter;
    late OffsiteRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      source = OffsiteRemoteDataSourceImpl(
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
      );
    });

    Map<String, dynamic> row(String id) => {
      'id': id,
      'method': 'check_in',
      'scan_timestamp': '2026-10-02 08:15:00',
      'scan_date': '2026-10-02',
      'session_order': 1,
      'reason': 'With a customer',
      'status': 'pending',
      'created_at': '2026-10-02 08:15:00',
      'steps': [
        {
          'id': 'step-1',
          'step_no': 1,
          'step_role': 'specific',
          'approver': null,
          'status': 'approved',
          'note': 'ok',
          'acted_at': '2026-10-02 09:00:00',
          'created_at': '2026-10-02 08:15:00',
        },
      ],
    };

    test('one page: status, limit 20 and the cursor sent; the next cursor '
        'read', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [row('a'), row('b')],
          'meta': {'per_page': 20, 'has_more': true, 'next_cursor': 'c2'},
        };

      final page = await source.myRequests(
        status: TimeCorrectionStatus.pending,
        cursor: 'c1',
      );

      final q = adapter.lastRequest!.queryParameters;
      expect(adapter.lastRequest!.path, endsWith('/offsite-requests/my'));
      expect(q['status'], 'pending');
      expect(q['limit'], 20);
      expect(q['cursor'], 'c1');
      expect(q.containsKey('month'), isFalse);
      expect(page.items.map((r) => r.id), ['a', 'b']);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'c2');
    });

    test('"all": no status sent; the first page no cursor', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await source.myRequests();

      final q = adapter.lastRequest!.queryParameters;
      expect(q.containsKey('status'), isFalse);
      expect(q.containsKey('cursor'), isFalse);
    });

    test('a step with no approver, a specific role and acted_at is read',
        () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': row('a')};

      final request = await source.detail('a');

      expect(adapter.lastRequest!.path, endsWith('/offsite-requests/a'));
      final step = request.steps.single;
      expect(step.approverName, isNull);
      expect(step.note, 'ok');
      expect(step.actedAt, DateTime(2026, 10, 2, 9));
    });

    test('404 on a request: "not available"', () async {
      adapter
        ..status = 404
        ..body = {
          'success': false,
          'error': {'code': 'NOT_FOUND', 'message': 'not found'},
        };

      await expectLater(
        source.detail('gone'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            OffsiteErrorCode.tokenRequestGone,
          ),
        ),
      );
    });

    test('the send answer keeps the new request\'s id, for "View"', () async {
      adapter
        ..status = 201
        ..body = {
          'success': true,
          'data': {'id': 'new-1', 'status': 'pending'},
        };

      final outcome = await source.submit(request());

      expect((outcome as OffsiteFiled).submission.requestId, 'new-1');
    });
  });

  group('OffsiteRemoteDataSourceImpl approvals', () {
    late _StubAdapter adapter;
    late OffsiteRemoteDataSourceImpl source;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      source = OffsiteRemoteDataSourceImpl(ApiClient(dio: dio));
    });

    test('asks the endpoint for one status bucket', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': []};

      await source.approvals(status: TimeCorrectionStatus.pending);

      expect(
        adapter.lastRequest?.path,
        '/core_hr/attendance/offsite-requests/my-approvals',
      );
      expect(adapter.lastRequest?.queryParameters['status'], 'pending');
    });

    test('drops an entry it cannot read rather than the whole page', () async {
      adapter
        ..status = 200
        ..body = {
          'success': true,
          'data': [
            {
              'id': 'ok',
              'method': 'check_out',
              'created_at': '2026-10-02 09:00:00',
            },
            {'method': 'check_out'},
          ],
        };

      final requests = await source.approvals();

      expect(requests.items.map((r) => r.id), ['ok']);
    });

    test('a decision sends the step it was aimed at', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': {}};

      await source.approve('req-1', stepId: 'step-1');

      expect(
        adapter.lastRequest?.path,
        '/core_hr/attendance/offsite-requests/req-1/approve',
      );
      expect(adapter.lastRequest?.method, 'PUT');
      expect(adapter.lastBody, contains('step-1'));
    });

    test('a rejection sends the trimmed note §8 requires', () async {
      adapter
        ..status = 200
        ..body = {'success': true, 'data': {}};

      await source.reject('req-1', note: '  not enough  ', stepId: 'step-1');

      expect(
        adapter.lastRequest?.path,
        '/core_hr/attendance/offsite-requests/req-1/reject',
      );
      expect(adapter.lastBody, contains('"note":"not enough"'));
    });

    test('a documented refusal becomes a token the localizer knows', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'STEP_CHANGED', 'message': 'moved on'},
        };

      await expectLater(
        source.approve('req-1'),
        throwsA(
          isA<Failure>().having(
            (f) => f.message,
            'token',
            LeaveErrorCode.tokenStepChanged,
          ),
        ),
      );
    });

    test('the punch a final approval writes can still be too early', () async {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {
            'code': 'TOO_EARLY_CHECKIN',
            'details': {'clock_in_opens': '07:45'},
          },
        };

      await expectLater(
        source.approve('req-1'),
        throwsA(
          isA<Failure>().having(
            (f) => f.message,
            'token',
            OffsiteErrorCode.tokenTooEarlyCheckin,
          ),
        ),
      );
    });

    test('an unknown decision refusal stays a transport error', () {
      adapter
        ..status = 409
        ..body = {
          'success': false,
          'error': {'code': 'SOMETHING_NEW', 'message': 'nope'},
        };

      expect(source.approve('req-1'), throwsA(isA<DioException>()));
    });
  });
}
