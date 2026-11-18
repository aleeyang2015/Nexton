import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_remote_data_source.dart';
import 'package:next_on/features/attendance/data/repositories/offsite_repository_impl.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

/// An approver's decision on an off-site scan (#46): every refusal the issue
/// names comes back as its own token, through the App's real error mapping.
void main() {
  final en = AppLocalizationsEn();
  late _StubAdapter adapter;
  late OffsiteRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    // The App's own interceptor, which turns a 403 into `Failure.auth` when
    // nothing reads the code first.
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    repository = OffsiteRepositoryImpl(
      remote: OffsiteRemoteDataSourceImpl(ApiClient(dio: dio)),
    );
  });

  void refuse(int status, String code) {
    adapter
      ..status = status
      ..body = {
        'success': false,
        'error': {'code': code, 'message': 'refused: $code'},
      };
  }

  Future<Failure> approveFails() async =>
      (await repository.approve('o-1', stepId: 's-1')).failureOrNull!;

  group('every code is its own token', () {
    final table = <(int, String, String)>[
      (409, 'NOT_PENDING', OffsiteErrorCode.tokenAlreadyDecided),
      (409, 'STEP_CHANGED', LeaveErrorCode.tokenStepChanged),
      (403, 'NOT_APPROVER', OffsiteErrorCode.tokenAnotherApprover),
      (409, 'CHECKIN_PENDING_APPROVAL', OffsiteErrorCode.tokenApproveCheckinFirst),
      (409, 'CHECKIN_NOT_APPROVED', OffsiteErrorCode.tokenCheckinNotApproved),
      (409, 'TOO_EARLY_CHECKIN', OffsiteErrorCode.tokenTooEarlyCheckin),
      (400, 'EMPLOYEE_NOT_FOUND', LeaveErrorCode.tokenEmployeeNotFound),
    ];
    for (final (status, code, token) in table) {
      test('$status $code', () async {
        refuse(status, code);
        final failure = await approveFails();
        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).message, token);
        expect(failure.code, code);
      });
    }
  });

  test('a 403 NOT_APPROVER is not Failure.auth (which the App hides)', () async {
    refuse(403, 'NOT_APPROVER');
    final failure = await approveFails();
    expect(failure, isNot(isA<AuthFailure>()));
    expect(failure.localize(en), en.apprAnotherApprover);
  });

  test('the Lao and English texts the issue names', () async {
    for (final (code, text) in [
      ('NOT_PENDING', en.apprAlreadyDecided),
      ('CHECKIN_PENDING_APPROVAL', en.apprApproveCheckinFirst),
      ('CHECKIN_NOT_APPROVED', en.apprCheckinNotApproved),
    ]) {
      refuse(409, code);
      expect((await approveFails()).localize(en), text);
    }
    expect(
      const Failure.validation(
        message: OffsiteErrorCode.tokenCannotDecideOwn,
      ).localize(en),
      en.apprCannotDecideOwn,
    );
  });

  test('404: "not available"', () async {
    refuse(404, 'NOT_FOUND');
    final failure = await approveFails();
    expect(
      (failure as ValidationFailure).message,
      OffsiteErrorCode.tokenRequestGone,
    );
    expect(failure.localize(en), en.apprRequestNotFound);
  });

  test('a 500 is not dressed up as a rule', () async {
    refuse(500, 'INTERNAL');
    final failure = await approveFails();
    expect(failure, isNot(isA<ValidationFailure>()));
  });

  test('reject refuses the same way', () async {
    refuse(409, 'NOT_PENDING');
    final failure = (await repository.reject(
      'o-1',
      note: 'No',
      stepId: 's-1',
    )).failureOrNull!;
    expect(
      (failure as ValidationFailure).message,
      OffsiteErrorCode.tokenAlreadyDecided,
    );
  });

  group('the calls', () {
    test('approve sends the step and the note; a blank note is left out', () async {
      adapter.body = {'success': true, 'data': {}};

      await repository.approve('o-1', stepId: 's-1', note: '  Fine  ');
      expect(jsonDecode(adapter.lastBody!), {'step_id': 's-1', 'note': 'Fine'});

      await repository.approve('o-1', stepId: 's-1', note: '   ');
      expect(jsonDecode(adapter.lastBody!), {'step_id': 's-1'});
    });

    test('my-approvals: the status, limit 20 and the cursor', () async {
      adapter.body = {
        'success': true,
        'data': <Object>[],
        'meta': {'has_more': false},
      };

      await repository.approvals(
        status: TimeCorrectionStatus.pending,
        cursor: 'c1',
      );

      final query = adapter.lastRequest!.queryParameters;
      expect(adapter.lastRequest!.path, endsWith('offsite-requests/my-approvals'));
      expect(query['status'], 'pending');
      expect(query['limit'], 20);
      expect(query['cursor'], 'c1');
      expect(query.containsKey('page'), isFalse);
    });

    test('rows carry the employee\'s id and each step its approver\'s', () async {
      adapter.body = {
        'success': true,
        'data': [
          {
            'id': 'o-1',
            'method': 'check_in',
            'created_at': '2026-11-18 09:00:00',
            'employee': {'id': 'e-1', 'name': 'Noy'},
            'steps': [
              {
                'id': 's-1',
                'step_no': 1,
                'step_role': 'specific',
                'status': 'pending',
                'approver': {'id': 'e-head', 'name': 'Boss'},
              },
            ],
          },
        ],
      };

      final page = (await repository.approvals(
        status: TimeCorrectionStatus.pending,
      )).dataOrNull!;

      final row = page.items.single;
      expect(row.employee.id, 'e-1');
      expect(row.steps.single.approverId, 'e-head');
    });
  });
}

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
