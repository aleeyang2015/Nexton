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

  /// Every request, in order, for a call that makes more than one.
  final List<RequestOptions> requests = [];

  /// When set, answers each request by itself instead of with [body].
  Object Function(RequestOptions options)? respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastBody = options.data;
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond?.call(options) ?? body),
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
        'filters and limit=20, and no cursor for the first page', () async {
      answerList();

      final page = await source.myRequests(
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
        'limit': 20,
      });
      expect(page.items.single.id, 'req-1');
      // No meta in the answer: one page, nothing after it.
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('myRequests sends the cursor with the same filters for a later '
        'page, and reads where to go on from', () async {
      adapter.body = {
        'success': true,
        'data': [_requestJson],
        'meta': {'per_page': 20, 'has_more': true, 'next_cursor': 'c-3'},
      };

      final page = await source.myRequests(
        LeaveHistoryQuery(
          leaveTypeId: 'lt-annual',
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 30),
        ),
        cursor: 'c-2',
      );

      expect(query(), {
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'leave_type_id': 'lt-annual',
        'limit': 20,
        'cursor': 'c-2',
      });
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'c-3');
    });

    test('myRequests: a cursor the server refuses is a failed page, with '
        'the server\'s code, through the repository', () async {
      refuse(400, 'VALIDATION_ERROR');

      final result = await LeaveRepositoryImpl(remote: source).myRequests(
        LeaveHistoryQuery(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 30)),
        cursor: 'broken',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
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
      'LEAVE_CHANGED': 'leaveChanged',
      'LEAVE_ALREADY_STARTED': 'leaveStartedContactHr',
    };

    test('the table the data source reads has exactly these nine codes', () {
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

    test('NOT_FOUND on a call about one request means that request is gone',
        () async {
      refuse(404, 'NOT_FOUND');
      final isGone = throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'leaveRequestGone',
        ),
      );

      await expectLater(source.update('req-1', draft), isGone);
      await expectLater(source.cancel('req-1'), isGone);
      await expectLater(source.approve(id: 'req-1'), isGone);
      await expectLater(source.reject(id: 'req-1', reason: 'no'), isGone);
    });

    test('NOT_FOUND on creating a request is not "the request is gone": it '
        'rethrows', () async {
      refuse(404, 'NOT_FOUND');

      await expectLater(source.submit(draft), throwsA(isA<DioException>()));
    });

    test('an unknown code rethrows the DioException untouched', () async {
      refuse(409, 'LEAVE_SPAN_TOO_LONG');

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
      await expectLater(source.myApprovals(), throwsA(isA<DioException>()));
      await expectLater(source.pendingRequest(), throwsA(isA<DioException>()));
    });

    test('loading one request by id: a 404 means it is gone, and the '
        'no-staff-record refusal keeps its own text', () async {
      refuse(404, 'NOT_FOUND');
      await expectLater(
        source.requestDetail('req-1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'leaveRequestGone',
          ),
        ),
      );

      refuse(400, 'EMPLOYEE_NOT_FOUND');
      await expectLater(
        source.requestDetail('req-1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'leaveEmployeeNotFound',
          ),
        ),
      );
    });

    test('loading one request by id: no signal or a 500 rethrows, to be '
        'retried', () async {
      refuse(500, 'INTERNAL');

      await expectLater(
        source.requestDetail('req-1'),
        throwsA(isA<DioException>()),
      );
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
      refuse(409, 'LEAVE_SPAN_TOO_LONG');

      final result = await repository.submit(draft);

      expect(result.isFailure, isTrue);
    });
  });

  group('restDays', () {
    Map<String, dynamic> row(String type, String value) => {
      'id': 'rd-$value',
      'name': value,
      'type': type,
      'value': value,
    };

    test('asks /core_hr/rest-days for 100 a page', () async {
      adapter.body = {
        'success': true,
        'data': [row('weekly', 'SUN')],
        'meta': {'page': 1, 'per_page': 100, 'total': 1, 'total_pages': 1},
      };

      final daysOff = await source.restDays();

      expect(adapter.requests, hasLength(1));
      expect(adapter.lastRequest!.path, '/core_hr/rest-days');
      expect(adapter.lastRequest!.queryParameters, {
        'page': 1,
        'per_page': 100,
      });
      expect(daysOff.isDayOff(DateTime(2026, 11, 22)), isTrue);
    });

    test('reads two pages when the answer says there are two', () async {
      adapter.respond = (options) {
        final page = options.queryParameters['page'];
        return {
          'success': true,
          'data': [
            page == 1 ? row('weekly', 'SUN') : row('custom', '2026-11-25'),
          ],
          'meta': {'page': page, 'per_page': 100, 'total': 2, 'total_pages': 2},
        };
      };

      final daysOff = await source.restDays();

      expect(
        [for (final r in adapter.requests) r.queryParameters['page']],
        [1, 2],
      );
      expect(daysOff.rules, hasLength(2));
      expect(daysOff.isDayOff(DateTime(2026, 11, 22)), isTrue);
      // The rule on the second page counts too.
      expect(daysOff.isDayOff(DateTime(2026, 11, 25)), isTrue);
    });

    test('an answer with no meta is one page', () async {
      adapter.body = {
        'success': true,
        'data': [row('monthly', '08')],
      };

      final daysOff = await source.restDays();

      expect(adapter.requests, hasLength(1));
      expect(daysOff.isDayOff(DateTime(2026, 11, 8)), isTrue);
    });

    test('no rows: a company with no days off', () async {
      adapter.body = {'success': true, 'data': <Object>[]};

      expect((await source.restDays()).rules, isEmpty);
    });

    test(
      'a total_pages that is wrong does not keep it asking for ever',
      () async {
        adapter.respond = (_) => {
          'success': true,
          'data': <Object>[],
          'meta': {'total_pages': 100000},
        };

        await source.restDays();

        expect(adapter.requests.length, lessThanOrEqualTo(20));
      },
    );

    test(
      'a failed page fails the whole read, through the repository',
      () async {
        adapter.respond = (options) => options.queryParameters['page'] == 1
            ? {
                'success': true,
                'data': [row('weekly', 'SUN')],
                'meta': {'total_pages': 2},
              }
            : {
                'success': false,
                'error': {'code': 'INTERNAL', 'message': 'boom'},
              };

        final result = await LeaveRepositoryImpl(
          remote: source,
        ).companyDaysOff();

        // Half a list would grey out some days off and not others.
        expect(result.isFailure, isTrue);
      },
    );
  });

  test('an id is sent as one path segment, whatever it holds', () async {
    answerOne();

    await source.requestDetail('../my');
    expect(adapter.lastRequest!.path, '/core_hr/leave/requests/..%2Fmy');

    await source.cancel('a/b');
    expect(adapter.lastRequest!.path, '/core_hr/leave/requests/a%2Fb/cancel');

    // A UUID goes through as it is.
    await source.requestDetail('0b1f6c2e-8f0a-4a57-9a53-0d3b3f3f8c11');
    expect(
      adapter.lastRequest!.path,
      '/core_hr/leave/requests/0b1f6c2e-8f0a-4a57-9a53-0d3b3f3f8c11',
    );
  });

  group('pendingRequest', () {
    test('asks for one pending request of the caller\'s', () async {
      answerList();

      final request = await source.pendingRequest();

      expect(adapter.lastRequest!.path, '/core_hr/leave/requests/my');
      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.queryParameters, {
        'status': 'pending',
        'limit': 1,
      });
      expect(request!.id, 'req-1');
    });

    test('an empty list means none is waiting', () async {
      adapter.body = {'success': true, 'data': <Object>[]};

      expect(await source.pendingRequest(), isNull);
    });
  });
}
