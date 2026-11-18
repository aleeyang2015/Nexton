import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/data/datasources/ot_remote_data_source.dart';
import 'package:next_on/features/overtime/data/repositories/ot_repository_impl.dart';
import 'package:next_on/features/overtime/domain/entities/ot_draft.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';

import '../../support/overtime_json.dart';

/// Serves one canned response and records the request that asked for it.
class _StubAdapter implements HttpClientAdapter {
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

/// The employee's OT calls (`/core_hr/attendance`): what each sends, what
/// it reads back, and what each refusal becomes.
void main() {
  late _StubAdapter adapter;
  late OtRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    // The App's own error interceptor, so a refusal reaches the repository
    // the way it does in the App.
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    repository = OtRepositoryImpl(
      remote: OtRemoteDataSourceImpl(ApiClient(dio: dio)),
    );
  });

  void answer(int status, Object data) => adapter
    ..status = status
    ..body = {'success': true, 'data': data};

  void refuse(
    int status,
    String code, [
    String message = 'refused',
    Map<String, dynamic>? errors,
  ]) => adapter
    ..status = status
    ..body = {
      'success': false,
      'error': {'code': code, 'message': message},
      // A 422 also puts the summary and the field errors at the top level.
      if (errors != null) 'message': message,
      if (errors != null) 'errors': errors,
    };

  Map<String, dynamic> sentBody() =>
      jsonDecode(adapter.lastBody!) as Map<String, dynamic>;

  final draft = OtDraft(
    workDate: DateTime(2026, 11, 14),
    startTime: '18:00',
    endTime: '20:00',
    reason: '  Wedding dinner  ',
  );

  Map<String, dynamic> listBody(List<Object> rows, {int page = 1, int pages = 1}) => {
    'success': true,
    'data': rows,
    'meta': {'page': page, 'per_page': 20, 'total': rows.length, 'total_pages': pages},
  };

  group('ask', () {
    test('POST /core_hr/attendance/ot-requests with the day, the times as '
        'given and the reason trimmed; 201 is the new request', () async {
      answer(201, otRequestJson());

      final result = await repository.ask(draft);

      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.path, '/core_hr/attendance/ot-requests');
      expect(sentBody(), {
        'work_date': '2026-11-14',
        'start_time': '18:00',
        'end_time': '20:00',
        'reason': 'Wedding dinner',
      });
      expect(result.dataOrNull?.id, 'ot-1');
    });

    test('an empty reason, or only spaces, is not sent', () async {
      answer(201, otRequestJson());

      await repository.ask(
        OtDraft(
          workDate: DateTime(2026, 1, 5),
          startTime: '06:00',
          endTime: '07:30',
          reason: '   ',
        ),
      );
      expect(sentBody(), {
        'work_date': '2026-01-05',
        'start_time': '06:00',
        'end_time': '07:30',
      });

      await repository.ask(
        OtDraft(workDate: DateTime(2026, 1, 5), startTime: '06:00', endTime: '07:30'),
      );
      expect(sentBody().containsKey('reason'), isFalse);
    });
  });

  group('my list', () {
    test('GET /ot-requests/my with month YYYY-MM, page and per_page', () async {
      adapter.body = listBody([otRequestJson()]);

      await repository.myRequests(
        month: DateTime(2026, 3, 17),
        page: 2,
        perPage: 50,
      );

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/core_hr/attendance/ot-requests/my');
      expect(adapter.lastRequest!.queryParameters, {
        'month': '2026-03',
        'page': 2,
        'per_page': 50,
      });
    });

    test('status is sent only as one of the four values; none for all and '
        'for unknown', () async {
      adapter.body = listBody([]);

      for (final (status, wire) in [
        (OtStatus.pending, 'pending'),
        (OtStatus.approved, 'approved'),
        (OtStatus.rejected, 'rejected'),
        (OtStatus.cancelled, 'cancelled'),
      ]) {
        await repository.myRequests(status: status);
        expect(adapter.lastRequest!.queryParameters['status'], wire);
      }

      await repository.myRequests();
      expect(adapter.lastRequest!.queryParameters.containsKey('status'), isFalse);

      await repository.myRequests(status: OtStatus.unknown);
      expect(adapter.lastRequest!.queryParameters.containsKey('status'), isFalse);
    });

    test('the page is read from meta; rows the App cannot read are skipped',
        () async {
      adapter.body = listBody(
        [
          otRequestJson(),
          {...otRequestJson()}..remove('id'),
          'not a row',
          {...otRequestJson(), 'id': 'ot-2'},
        ],
        page: 2,
        pages: 3,
      );

      final page = (await repository.myRequests(page: 2)).dataOrNull!;

      expect(page.items.map((r) => r.id), ['ot-1', 'ot-2']);
      expect(page.page, 2);
      expect(page.totalPages, 3);
      expect(page.hasMore, isTrue);
    });

    test('the last page has no more; no meta is one page', () async {
      adapter.body = listBody([otRequestJson()], page: 3, pages: 3);
      expect((await repository.myRequests(page: 3)).dataOrNull!.hasMore, isFalse);

      adapter.body = {'success': true, 'data': <Object>[]};
      final page = (await repository.myRequests()).dataOrNull!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('a page number that is missing or not whole is the page asked for, '
        'so load-more never asks for a page twice', () async {
      adapter.body = {
        'success': true,
        'data': [otRequestJson()],
        'meta': {'page': '3', 'total_pages': 5},
      };
      final page = (await repository.myRequests(page: 3)).dataOrNull!;
      expect(page.page, 3);
      expect(page.hasMore, isTrue);

      adapter.body = {
        'success': true,
        'data': [otRequestJson()],
        'meta': {'total_pages': 3},
      };
      expect((await repository.myRequests(page: 3)).dataOrNull!.hasMore, isFalse);
    });

    test('a bad month is a 422 that keeps its field', () async {
      refuse(422, 'VALIDATION_ERROR', 'invalid month', {
        'month': ['must be YYYY-MM'],
      });

      final failure = (await repository.myRequests()).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'month');
    });
  });

  group('one request', () {
    test('detail: GET /ot-requests/:id, the id as one path segment', () async {
      answer(200, otRequestJson());

      await repository.request('../my');

      expect(adapter.lastRequest!.method, 'GET');
      expect(
        adapter.lastRequest!.path,
        '/core_hr/attendance/ot-requests/..%2Fmy',
      );
    });

    test('an empty id, "." or ".." is refused before any request goes out: '
        'it would step out of the path', () async {
      answer(200, otRequestJson());

      for (final id in ['', '.', '..']) {
        adapter.lastRequest = null;
        expect((await repository.request(id)).isFailure, isTrue, reason: id);
        expect((await repository.cancel(id)).isFailure, isTrue, reason: id);
        expect((await repository.join(id)).isFailure, isTrue, reason: id);
        expect(adapter.lastRequest, isNull, reason: id);
      }
    });

    test('edit: PUT /ot-requests/:id with the same body as ask', () async {
      answer(200, otRequestJson());

      await repository.edit('ot-1', draft);

      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, '/core_hr/attendance/ot-requests/ot-1');
      expect(sentBody()['reason'], 'Wedding dinner');
      expect(sentBody()['work_date'], '2026-11-14');
    });

    test('cancel: PUT /ot-requests/:id/cancel with no body; warnings are '
        'ignored', () async {
      answer(200, {
        ...otRequestJson(),
        'status': 'cancelled',
        'warnings': ['something'],
      });

      final result = await repository.cancel('ot-1');

      expect(adapter.lastRequest!.method, 'PUT');
      expect(
        adapter.lastRequest!.path,
        '/core_hr/attendance/ot-requests/ot-1/cancel',
      );
      expect(adapter.lastBody, isNull);
      expect(result.dataOrNull?.status, OtStatus.cancelled);
    });

    test('404 keeps its status, for the screen to go back and refresh',
        () async {
      refuse(404, 'NOT_FOUND', 'OT request not found');

      final failure = (await repository.request('ot-x')).failureOrNull!;

      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 404);
    });
  });

  group('HR posts', () {
    test('open posts: GET /ot-announcements/open with page and per_page',
        () async {
      adapter.body = listBody([otPostJson()], pages: 2);

      final page = (await repository.openPosts(page: 1, perPage: 20)).dataOrNull!;

      expect(adapter.lastRequest!.method, 'GET');
      expect(
        adapter.lastRequest!.path,
        '/core_hr/attendance/ot-announcements/open',
      );
      expect(adapter.lastRequest!.queryParameters, {'page': 1, 'per_page': 20});
      expect(page.items.single.id, 'post-1');
      expect(page.hasMore, isTrue);
    });

    test('join: POST /ot-announcements/:id/join with no body; 201 is my '
        'request', () async {
      answer(201, {...otRequestJson(), 'announcement_id': 'post-1'});

      final result = await repository.join('post-1');

      expect(adapter.lastRequest!.method, 'POST');
      expect(
        adapter.lastRequest!.path,
        '/core_hr/attendance/ot-announcements/post-1/join',
      );
      expect(adapter.lastBody, isNull);
      expect(result.dataOrNull?.announcementId, 'post-1');
    });
  });

  group('refusals', () {
    /// Every OT code and the token it becomes, on the call that can answer
    /// it.
    const codes = {
      'OT_DISABLED': OtErrorCode.tokenDisabled,
      'OT_NOT_ELIGIBLE': OtErrorCode.tokenNotEligible,
      'OT_TOO_FAR_BACK': OtErrorCode.tokenTooFarBack,
      'OT_OVERLAP': OtErrorCode.tokenOverlap,
      'OT_OVERLAPS_SHIFT': OtErrorCode.tokenOverlapsShift,
      'OT_EMPLOYEE_LEFT': OtErrorCode.tokenEmployeeLeft,
      'OT_ALREADY_DECIDED': OtErrorCode.tokenAlreadyDecided,
      'OT_ANNOUNCED': OtErrorCode.tokenAnnounced,
      'OT_FULL': OtErrorCode.tokenFull,
      'OT_JOIN_CLOSED': OtErrorCode.tokenJoinClosed,
      'STEP_CHANGED': OtErrorCode.tokenStepChanged,
      'OT_STARTED': OtErrorCode.tokenStarted,
      'OT_ALREADY_PAID': OtErrorCode.tokenAlreadyPaid,
      'OT_PAID_BY_HAND': OtErrorCode.tokenPaidByHand,
    };

    for (final MapEntry(key: code, value: token) in codes.entries) {
      test('409 $code is the token $token', () async {
        refuse(409, code, 'English text from the server');

        final failure = (await repository.ask(draft)).failureOrNull!;

        expect(failure, isA<ValidationFailure>());
        expect(failure.message, token);
        // The wire code is kept beside the token.
        expect((failure as ValidationFailure).code, code);
      });
    }

    test('a 500 that carries an OT code is a server failure, worth a Retry',
        () async {
      refuse(500, 'OT_FULL', 'boom');

      final failure = (await repository.join('post-1')).failureOrNull!;

      expect(failure, isA<ServerFailure>());
      expect(failure.message, isNot(OtErrorCode.tokenFull));
    });

    test('409 OT_OVERLAPS_SHIFT on edit and join too', () async {
      refuse(409, 'OT_OVERLAPS_SHIFT');
      expect(
        (await repository.edit('ot-1', draft)).failureOrNull!.message,
        OtErrorCode.tokenOverlapsShift,
      );

      refuse(409, 'OT_FULL');
      expect(
        (await repository.join('post-1')).failureOrNull!.message,
        OtErrorCode.tokenFull,
      );
    });

    test('403 NOT_APPROVER is a refusal with its token, not a sign-in failure',
        () async {
      refuse(403, 'NOT_APPROVER', 'not your step');

      final failure = (await repository.cancel('ot-1')).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect(failure, isNot(isA<AuthFailure>()));
      expect(failure.message, OtErrorCode.tokenNotApprover);
    });

    test('403 FORBIDDEN on cancel: "reject it instead"', () async {
      refuse(403, 'FORBIDDEN', 'forbidden');

      final failure = (await repository.cancel('ot-1')).failureOrNull!;

      expect(failure.message, OtErrorCode.tokenCancelForbidden);
    });

    test('403 FORBIDDEN on any other call is not mapped: it keeps its code',
        () async {
      refuse(403, 'FORBIDDEN', 'forbidden');

      final failure = (await repository.ask(draft)).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, isNot(OtErrorCode.tokenCancelForbidden));
      expect((failure as ValidationFailure).code, 'FORBIDDEN');
    });

    test('400 EMPLOYEE_NOT_FOUND keeps its code, for #4\'s shared text',
        () async {
      refuse(400, 'EMPLOYEE_NOT_FOUND', 'employee not found');

      final failure = (await repository.ask(draft)).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, ApiErrorCodes.employeeNotFound);
    });

    test('422 VALIDATION_ERROR keeps its field', () async {
      refuse(422, 'VALIDATION_ERROR', 'end_time must differ from start_time', {
        'end_time': ['must differ from start_time'],
      });

      final failure = (await repository.ask(draft)).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'end_time');
    });

    test('a code the App does not know keeps the server\'s message', () async {
      refuse(409, 'OT_SOMETHING_NEW', 'Something new happened');

      final failure = (await repository.ask(draft)).failureOrNull!;

      expect(failure.message, 'Something new happened');
    });

    test('a body that is not a request is a failure, not a crash', () async {
      answer(201, 'nope');

      expect((await repository.ask(draft)).isFailure, isTrue);
    });
  });

  group('my approvals (#48)', () {
    test('sends the status and page / per_page, never a limit or cursor',
        () async {
      adapter.body = {
        'success': true,
        'data': [otRequestJson()],
        'meta': {'page': 2, 'per_page': 20, 'total': 25, 'total_pages': 2},
      };

      final page = (await repository.myApprovals(
        status: OtApprovalStatus.approved,
        page: 2,
      )).dataOrNull!;

      final query = adapter.lastRequest!.queryParameters;
      expect(adapter.lastRequest!.path, endsWith('ot-requests/my-approvals'));
      expect(query['status'], 'approved');
      expect(query['page'], 2);
      expect(query['per_page'], 20);
      expect(query.containsKey('limit'), isFalse);
      expect(query.containsKey('cursor'), isFalse);
      expect(page.page, 2);
      expect(page.hasMore, isFalse);
      expect(page.items.single.employeeName, isNotNull);
    });

    test('always one of pending / approved / rejected', () async {
      adapter.body = {'success': true, 'data': <Object>[]};
      for (final status in OtApprovalStatus.values) {
        await repository.myApprovals(status: status);
        expect(adapter.lastRequest!.queryParameters['status'], status.name);
      }
    });

    test('no staff record: #28\'s refusal, not a crash', () async {
      refuse(400, 'EMPLOYEE_NOT_FOUND');
      final failure = (await repository.myApprovals(
        status: OtApprovalStatus.pending,
      )).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      // The tab tells it apart by this code (#28's text, no Retry).
      expect((failure! as ValidationFailure).code, 'EMPLOYEE_NOT_FOUND');
    });
  });

  group('the employee\'s department (live since 15 Nov)', () {
    Map<String, dynamic> withDepartment(Object? department) {
      final json = otRequestJson();
      final employee = Map<String, dynamic>.from(json['employee'] as Map);
      if (department == null) {
        employee.remove('department');
      } else {
        employee['department'] = department;
      }
      return {...json, 'employee': employee};
    }

    test('name and name_lo', () async {
      answer(200, withDepartment({'id': 'd-1', 'name': 'Kitchen', 'name_lo': 'ຄົວ'}));
      final request = (await repository.request('ot-1')).dataOrNull!;
      expect(request.departmentName, 'Kitchen');
      expect(request.departmentNameLo, 'ຄົວ');
    });

    test('name_lo null; or no department at all', () async {
      answer(200, withDepartment({'id': 'd-1', 'name': 'Kitchen', 'name_lo': null}));
      final noLao = (await repository.request('ot-1')).dataOrNull!;
      expect(noLao.departmentName, 'Kitchen');
      expect(noLao.departmentNameLo, isNull);

      answer(200, withDepartment(null));
      final none = (await repository.request('ot-1')).dataOrNull!;
      expect(none.departmentName, isNull);
    });
  });

  group('a head decides (#49)', () {
    test('approve: step_id always, comment when typed, never pieces; the '
        'answer is read and its warnings ignored', () async {
      adapter.body = {
        'success': true,
        'data': {...otRequestJson(), 'warnings': ['over the monthly cap']},
      };

      final request = (await repository.approve(
        'ot-1',
        stepId: 'step-1',
        comment: '  ok  ',
      )).dataOrNull;
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, endsWith('ot-requests/ot-1/approve'));
      expect(jsonDecode(adapter.lastBody!), {'step_id': 'step-1', 'comment': 'ok'});
      expect(request, isNotNull);

      await repository.approve('ot-1', stepId: 'step-1', comment: ' ');
      expect(jsonDecode(adapter.lastBody!), {'step_id': 'step-1'});
    });

    test('reject: step_id and comment, never pieces', () async {
      answer(200, otRequestJson());
      await repository.reject('ot-1', stepId: 'step-1', comment: ' No stock ');
      expect(adapter.lastRequest!.path, endsWith('ot-requests/ot-1/reject'));
      final body = jsonDecode(adapter.lastBody!) as Map;
      expect(body, {'step_id': 'step-1', 'comment': 'No stock'});
      expect(body.containsKey('pieces'), isFalse);
    });

    test('reject without a reason (422 errors.comment): "Write a reason"',
        () async {
      refuse(422, 'VALIDATION_ERROR', 'invalid', {
        'comment': ['required'],
      });
      final failure = (await repository.reject(
        'ot-1',
        stepId: 'step-1',
        comment: '',
      )).failureOrNull;
      expect(
        (failure as ValidationFailure).message,
        OtErrorCode.tokenReasonRequired,
      );
    });

    test('every refusal keeps #28\'s token; a 403 is not Failure.auth',
        () async {
      for (final (status, code, token) in [
        (409, 'STEP_CHANGED', OtErrorCode.tokenStepChanged),
        (409, 'OT_ALREADY_DECIDED', OtErrorCode.tokenAlreadyDecided),
        (403, 'NOT_APPROVER', OtErrorCode.tokenNotApprover),
        (409, 'OT_DISABLED', OtErrorCode.tokenDisabled),
        (409, 'OT_NOT_ELIGIBLE', OtErrorCode.tokenNotEligible),
      ]) {
        refuse(status, code);
        final failure = (await repository.approve(
          'ot-1',
          stepId: 'step-1',
        )).failureOrNull;
        expect(failure, isA<ValidationFailure>(), reason: code);
        expect((failure! as ValidationFailure).message, token, reason: code);
      }
    });

    test('cancel by a head: OT_STARTED, OT_ALREADY_PAID, OT_PAID_BY_HAND, '
        'and FORBIDDEN says "reject it instead"', () async {
      for (final (status, code, token) in [
        (409, 'OT_STARTED', OtErrorCode.tokenStarted),
        (409, 'OT_ALREADY_PAID', OtErrorCode.tokenAlreadyPaid),
        (409, 'OT_PAID_BY_HAND', OtErrorCode.tokenPaidByHand),
        (403, 'FORBIDDEN', OtErrorCode.tokenCancelForbidden),
      ]) {
        refuse(status, code);
        final failure = (await repository.cancel('ot-1')).failureOrNull;
        expect((failure! as ValidationFailure).message, token, reason: code);
      }
    });
  });
}
