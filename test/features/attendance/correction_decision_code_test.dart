import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/attendance/data/datasources/approval_decision_code.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

/// An approver's decision on a "forgot to scan" request (#47): the same
/// refusals as off-site (#46), from one shared table, through the App's
/// real error mapping.
void main() {
  final en = AppLocalizationsEn();
  late _StubAdapter adapter;
  late AttendanceRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    // The App's own interceptor, which turns a 403 into `Failure.auth` when
    // nothing reads the code first.
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    repository = AttendanceRepositoryImpl(
      remote: AttendanceRemoteDataSourceImpl(ApiClient(dio: dio)),
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

  Future<Failure> approveFails() async => (await repository
          .approveTimeCorrection('tc-1', stepId: 's-1'))
      .failureOrNull!;

  group('every decision code is its own token', () {
    final table = <(int, String, String)>[
      (409, 'NOT_PENDING', ApprovalDecisionCode.tokenAlreadyDecided),
      (409, 'STEP_CHANGED', LeaveErrorCode.tokenStepChanged),
      (403, 'NOT_APPROVER', ApprovalDecisionCode.tokenAnotherApprover),
      (409, 'TOO_EARLY_CHECKIN', ApprovalDecisionCode.tokenTooEarlyCheckin),
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

  test('one table: off-site\'s holds every shared entry', () {
    for (final entry in ApprovalDecisionCode.tokenByWire.entries) {
      expect(OffsiteErrorCode.decisionTokenByWire[entry.key], entry.value);
      expect(ApprovalDecisionCode.correctionTokenByWire[entry.key], entry.value);
    }
    // No check-in refusals for a correction.
    expect(
      ApprovalDecisionCode.tokenByWire.containsKey('CHECKIN_NOT_APPROVED'),
      isFalse,
    );
  });

  test('a 403 NOT_APPROVER is not Failure.auth (which the App hides)', () async {
    refuse(403, 'NOT_APPROVER');
    final failure = await approveFails();
    expect(failure, isNot(isA<AuthFailure>()));
    expect(failure.localize(en), en.apprAnotherApprover);
  });

  test('too early: #8\'s "it isn\'t time to clock in yet", never "Approved"',
      () async {
    refuse(409, 'TOO_EARLY_CHECKIN');
    final text = (await approveFails()).localize(en);
    expect(text, en.ruleTooEarlyCheckin);
    expect(text, isNot(contains('Approved')));
  });

  test('"someone already decided" in the issue\'s words', () async {
    refuse(409, 'NOT_PENDING');
    expect((await approveFails()).localize(en), en.apprAlreadyDecided);
  });

  test('404: "not available"', () async {
    refuse(404, 'NOT_FOUND');
    final failure = await approveFails();
    expect(
      (failure as ValidationFailure).message,
      CorrectionErrorCode.tokenRequestGone,
    );
    expect(failure.localize(en), en.apprRequestNotFound);
  });

  test('a 500 is not dressed up as a rule', () async {
    refuse(500, 'INTERNAL');
    expect(await approveFails(), isNot(isA<ValidationFailure>()));
  });

  test('reject refuses the same way', () async {
    refuse(409, 'NOT_PENDING');
    final failure = (await repository.rejectTimeCorrection(
      'tc-1',
      note: 'No',
      stepId: 's-1',
    )).failureOrNull!;
    expect(
      (failure as ValidationFailure).message,
      ApprovalDecisionCode.tokenAlreadyDecided,
    );
  });

  group('the calls', () {
    test('approve sends the step and the note; a blank note is left out',
        () async {
      adapter.body = {'success': true, 'data': {}};

      await repository.approveTimeCorrection('tc-1', stepId: 's-1', note: ' Ok ');
      expect(jsonDecode(adapter.lastBody!), {'step_id': 's-1', 'note': 'Ok'});

      await repository.approveTimeCorrection('tc-1', stepId: 's-1', note: ' ');
      expect(jsonDecode(adapter.lastBody!), {'step_id': 's-1'});
    });

    test('my-approvals: the status, limit 20 and the cursor', () async {
      adapter.body = {
        'success': true,
        'data': [
          {
            'id': 'tc-1',
            'request_date': '2026-11-14',
            'correction_type': 'missing_check_out',
            'employee': {'id': 'e-1', 'name': 'Noy'},
            'steps': [
              {
                'id': 's-1',
                'step_no': 1,
                'step_role': 'dept_head',
                'status': 'pending',
                'approver': {'id': 'e-head', 'name': 'Lee'},
              },
            ],
          },
          {'id': 'broken'},
        ],
        'meta': {'has_more': true, 'next_cursor': 'c2'},
      };

      final page = (await repository.timeCorrectionApprovals(
        status: TimeCorrectionStatus.pending,
        cursor: 'c1',
      )).dataOrNull!;

      final query = adapter.lastRequest!.queryParameters;
      expect(
        adapter.lastRequest!.path,
        endsWith('correction-requests/my-approvals'),
      );
      expect(query['status'], 'pending');
      expect(query['limit'], 20);
      expect(query['cursor'], 'c1');
      expect(query.containsKey('page'), isFalse);
      final row = page.items.single;
      expect(row.employee.id, 'e-1');
      expect(row.steps.single.approverId, 'e-head');
      expect(page.nextCursor, 'c2');
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
