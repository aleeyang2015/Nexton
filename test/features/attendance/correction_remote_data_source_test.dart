import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';

/// The team's "forgot to scan" call (#50): by page number only.
void main() {
  late _StubAdapter adapter;
  late AttendanceRemoteDataSourceImpl source;

  setUp(() {
    adapter = _StubAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    source = AttendanceRemoteDataSourceImpl(ApiClient(dio: dio));
  });

  Map<String, dynamic> row(String id, String employeeId) => {
    'id': id,
    'request_date': '2026-11-14',
    'correction_type': 'missing_check_out',
    'status': 'approved',
    'employee': {'id': employeeId, 'name': 'Noy'},
  };

  test('team: page and per_page, the status; never limit or cursor', () async {
    adapter.body = {
      'success': true,
      'data': [row('tc-1', 'e-1')],
      'meta': {'page': 2, 'per_page': 20, 'total': 25, 'total_pages': 2},
    };

    final page = await source.teamTimeCorrections(
      status: TimeCorrectionStatus.approved,
      page: 2,
    );

    final query = adapter.lastRequest!.queryParameters;
    expect(adapter.lastRequest!.path, endsWith('correction-requests/team'));
    expect(query['page'], 2);
    expect(query['per_page'], 20);
    expect(query['status'], 'approved');
    expect(query.containsKey('limit'), isFalse);
    expect(query.containsKey('cursor'), isFalse);
    expect(page.page, 2);
    expect(page.hasMore, isFalse);
    expect(page.items.single.employee.id, 'e-1');
  });

  test('no meta: one page; a broken row is skipped', () async {
    adapter.body = {
      'success': true,
      'data': [
        row('tc-1', 'e-1'),
        {'id': 'broken'},
      ],
    };

    final page = await source.teamTimeCorrections();

    expect(adapter.lastRequest!.queryParameters.containsKey('status'), false);
    expect(page.items.map((r) => r.id), ['tc-1']);
    expect(page.hasMore, isFalse);
  });
}

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
