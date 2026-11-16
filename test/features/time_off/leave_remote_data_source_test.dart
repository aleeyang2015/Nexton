import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/features/time_off/data/datasources/leave_remote_data_source.dart';
import 'package:next_on/features/time_off/data/repositories/leave_repository_impl.dart';
import 'package:next_on/features/time_off/domain/entities/leave_history_query.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request_draft.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

/// Serves one canned response and records the request that asked for it —
/// the same double the attendance data-source tests use, kept file-local.
class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = const <String, dynamic>{};
  RequestOptions? lastRequest;
  Object? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastBody = options.data;
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

const _requestJson = {
  'id': 'req-1',
  'leave_type': {'id': 'lt-annual', 'code': 'annual', 'name': 'Annual Leave'},
  'start_date': '2026-11-18',
  'end_date': '2026-11-19',
  'total_days': 2,
  'status': 'pending',
};

void main() {
  late _StubAdapter adapter;
  late LeaveRemoteDataSourceImpl source;

  setUp(() {
    adapter = _StubAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    source = LeaveRemoteDataSourceImpl(ApiClient(dio: dio));
  });

  void answerOne() => adapter
    ..status = 200
    ..body = {'success': true, 'data': _requestJson};

  void answerList() => adapter
    ..status = 200
    ..body = {
      'success': true,
      'data': [_requestJson],
    };

  void refuse(int status, String code) => adapter
    ..status = status
    ..body = {
      'success': false,
      'error': {'code': code, 'message': 'server english'},
    };

  final draft = LeaveRequestDraft(
    leaveTypeId: 'lt-annual',
    dates: [DateTime(2026, 11, 19), DateTime(2026, 11, 18)],
    reason: 'Trip',
  );

  String path() => adapter.lastRequest!.path;
  String method() => adapter.lastRequest!.method;
  Map<String, dynamic> query() => adapter.lastRequest!.queryParameters;

  group('each call\'s path and method', () {
    test('types: GET /core_hr/leave/types, 100 a page and unfiltered', () async {
      adapter.body = {
        'success': true,
        'data': [
          {'id': 'lt-annual', 'code': 'annual', 'name': 'Annual Leave'},
        ],
      };

      final types = await source.types();

      expect(method(), 'GET');
      expect(path(), '/core_hr/leave/types');
      // The endpoint sends 20 by default; a company can have more types. No
      // is_active filter: switched-off types still name old requests.
      expect(query(), {'per_page': 100});
      expect(types.single.id, 'lt-annual');
    });

    test('balances: GET /core_hr/leave/balances/my with the year', () async {
      adapter.body = {
        'success': true,
        'data': [
          {
            'leave_type_id': 'lt-annual',
            'leave_type_name': 'Annual Leave',
            'year': 2026,
            'total_days': 15,
            'used_days': 3,
            'pending_days': 2,
            'remaining_days': 10,
          },
        ],
      };

      final balances = await source.balances(2026);

      expect(method(), 'GET');
      expect(path(), '/core_hr/leave/balances/my');
      expect(query(), {'year': 2026});
      expect(balances.single.remainingDays, 10);
      expect(balances.single.pendingDays, 2);
    });

    test('myRequests: GET /core_hr/leave/requests/my with the range, the '
        'filters and one page of 100', () async {
      answerList();

      final requests = await source.myRequests(
        LeaveHistoryQuery(
          leaveTypeId: 'lt-annual',
          status: LeaveStatus.approved,
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 30),
        ),
      );

      expect(method(), 'GET');
      expect(path(), '/core_hr/leave/requests/my');
      expect(query(), {
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'leave_type_id': 'lt-annual',
        'status': 'approved',
        'page': 1,
        'per_page': 100,
      });
      expect(requests.single.id, 'req-1');
    });

    test('myRequests leaves out the filters that are not set', () async {
      answerList();

      await source.myRequests(
        LeaveHistoryQuery(from: DateTime(2026, 1, 5), to: DateTime(2026, 1, 9)),
      );

      expect(query().containsKey('leave_type_id'), isFalse);
      expect(query().containsKey('status'), isFalse);
      expect(query()['start_date'], '2026-01-05');
      expect(query()['end_date'], '2026-01-09');
    });

    test('requestDetail: GET /core_hr/leave/requests/:id', () async {
      answerOne();

      final request = await source.requestDetail('req-1');

      expect(method(), 'GET');
      expect(path(), '/core_hr/leave/requests/req-1');
      expect(request.id, 'req-1');
    });

    test('submit: POST /core_hr/leave/requests with the draft body', () async {
      answerOne();

      await source.submit(draft);

      expect(method(), 'POST');
      expect(path(), '/core_hr/leave/requests');
      expect(adapter.lastBody, {
        'leave_type_id': 'lt-annual',
        'dates': ['2026-11-18', '2026-11-19'],
        'duration_type': 'full_day',
        'reason': 'Trip',
      });
    });

    test('update: PUT /core_hr/leave/requests/:id with the draft body',
        () async {
      answerOne();

      await source.update('req-1', draft);

      expect(method(), 'PUT');
      expect(path(), '/core_hr/leave/requests/req-1');
      expect((adapter.lastBody! as Map)['dates'], ['2026-11-18', '2026-11-19']);
    });

    test('cancel: PUT /core_hr/leave/requests/:id/cancel with no body',
        () async {
      answerOne();

      await source.cancel('req-1');

      expect(method(), 'PUT');
      expect(path(), '/core_hr/leave/requests/req-1/cancel');
      expect(adapter.lastBody, isNull);
    });

    test('myApprovals: GET /core_hr/leave/requests/my-approvals, with the '
        'status when one is given', () async {
      answerList();

      await source.myApprovals(status: LeaveStatus.pending);

      expect(method(), 'GET');
      expect(path(), '/core_hr/leave/requests/my-approvals');
      expect(query(), {'status': 'pending', 'page': 1, 'per_page': 100});

      await source.myApprovals();

      expect(query(), {'page': 1, 'per_page': 100});
    });
  });

  group('approve', () {
    test('PUT /core_hr/leave/requests/:id/approve sends step_id', () async {
      answerOne();

      await source.approve(id: 'req-1', stepId: 'step-1');

      expect(method(), 'PUT');
      expect(path(), '/core_hr/leave/requests/req-1/approve');
      expect(adapter.lastBody, {'step_id': 'step-1'});
    });

    test('a note goes as approver_note, trimmed; a blank one is left out',
        () async {
      answerOne();

      await source.approve(id: 'req-1', stepId: 'step-1', note: '  ok  ');
      expect(adapter.lastBody, {'step_id': 'step-1', 'approver_note': 'ok'});

      await source.approve(id: 'req-1', stepId: 'step-1', note: '   ');
      expect(adapter.lastBody, {'step_id': 'step-1'});
    });

    test('with no step id the body is empty', () async {
      answerOne();

      await source.approve(id: 'req-1');

      expect(adapter.lastBody, <String, dynamic>{});
    });
  });

  group('reject', () {
    test('PUT /core_hr/leave/requests/:id/reject sends a trimmed reason and '
        'the step_id', () async {
      answerOne();

      await source.reject(
        id: 'req-1',
        reason: '  No cover that week \n',
        stepId: 'step-1',
      );

      expect(method(), 'PUT');
      expect(path(), '/core_hr/leave/requests/req-1/reject');
      expect(adapter.lastBody, {
        'reason': 'No cover that week',
        'step_id': 'step-1',
      });
    });
  });

  group('business refusals', () {
    const tokens = {
      'PENDING_REQUEST_EXISTS': 'leavePendingRequestExists',
      'OVERLAPPING_LEAVE': 'leaveOverlapping',
      'INSUFFICIENT_BALANCE': 'leaveInsufficientBalance',
      'STEP_CHANGED': 'leaveStepChanged',
      'NOT_APPROVER': 'leaveNotApprover',
      'INVALID_STATUS': 'leaveInvalidStatus',
      'EMPLOYEE_NOT_FOUND': 'leaveEmployeeNotFound',
    };

    test('the table the data source reads has exactly these seven codes', () {
      expect(LeaveErrorCode.tokenByWire, tokens);
    });

    for (final MapEntry(key: code, value: token) in tokens.entries) {
      test('$code becomes the token $token', () async {
        refuse(409, code);

        await expectLater(
          source.submit(draft),
          throwsA(
            isA<ValidationFailure>()
                .having((f) => f.message, 'message', token)
                // The token is the message; the failure carries no code.
                .having((f) => f.code, 'code', isNull),
          ),
        );
      });
    }

    test('every mutation maps a refusal the same way', () async {
      refuse(409, 'STEP_CHANGED');
      final isStepChanged = throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'leaveStepChanged',
        ),
      );

      await expectLater(source.update('req-1', draft), isStepChanged);
      await expectLater(source.cancel('req-1'), isStepChanged);
      await expectLater(source.approve(id: 'req-1'), isStepChanged);
      await expectLater(
        source.reject(id: 'req-1', reason: 'no'),
        isStepChanged,
      );
    });

    test('the status does not matter, only the code: a 422 maps too', () async {
      refuse(422, 'INSUFFICIENT_BALANCE');

      await expectLater(
        source.submit(draft),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'leaveInsufficientBalance',
          ),
        ),
      );
    });

    test('an unknown code rethrows the DioException untouched', () async {
      refuse(409, 'LEAVE_CHANGED');

      await expectLater(
        source.submit(draft),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            409,
          ),
        ),
      );
    });

    test('the read calls do not map codes: a refusal there rethrows', () async {
      refuse(400, 'EMPLOYEE_NOT_FOUND');

      await expectLater(source.types(), throwsA(isA<DioException>()));
      await expectLater(source.balances(2026), throwsA(isA<DioException>()));
      await expectLater(
        source.requestDetail('req-1'),
        throwsA(isA<DioException>()),
      );
      await expectLater(source.myApprovals(), throwsA(isA<DioException>()));
    });
  });

  group('LeaveRepositoryImpl, over the same data source', () {
    late LeaveRepositoryImpl repository;

    setUp(() => repository = LeaveRepositoryImpl(remote: source));

    test('approve passes the id, the step id and the note through', () async {
      answerOne();

      final result = await repository.approve(
        id: 'req-1',
        stepId: 'step-1',
        note: 'ok',
      );

      expect(result.isSuccess, isTrue);
      expect(path(), '/core_hr/leave/requests/req-1/approve');
      expect(adapter.lastBody, {'step_id': 'step-1', 'approver_note': 'ok'});
    });

    test('reject passes the id, the reason and the step id through', () async {
      answerOne();

      await repository.reject(id: 'req-1', reason: 'no', stepId: 'step-1');

      expect(path(), '/core_hr/leave/requests/req-1/reject');
      expect(adapter.lastBody, {'reason': 'no', 'step_id': 'step-1'});
    });

    test('update and cancel reach their own request', () async {
      answerOne();

      await repository.update('req-7', draft);
      expect(path(), '/core_hr/leave/requests/req-7');

      await repository.cancel('req-7');
      expect(path(), '/core_hr/leave/requests/req-7/cancel');
    });

    test('a refusal token thrown by the data source becomes a failed Result '
        'with that token', () async {
      refuse(409, 'STEP_CHANGED');

      final result = await repository.approve(id: 'req-1', stepId: 'step-1');

      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull,
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'leaveStepChanged',
        ),
      );
    });

    test('an unknown refusal becomes a failed Result too, never a throw',
        () async {
      refuse(409, 'LEAVE_CHANGED');

      final result = await repository.submit(draft);

      expect(result.isFailure, isTrue);
    });
  });
}
