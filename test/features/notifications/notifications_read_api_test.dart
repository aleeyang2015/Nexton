import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:next_on/features/notifications/data/repositories/notifications_repository_impl.dart';

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

/// The read / unread calls of the bell list (#55): what each sends and
/// what it makes of the answer.
void main() {
  late _StubAdapter adapter;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    // The App's own error interceptor, so a refusal reaches the repository
    // the way it does in the App.
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    repository = NotificationsRepositoryImpl(
      NotificationsRemoteDataSourceImpl(ApiClient(dio: dio)),
    );
  });

  group('the list', () {
    test('reads is_read on each row', () async {
      adapter.body = {
        'success': true,
        'data': [
          {
            'id': 'n-1',
            'notification_type': 'leave_request',
            'title': 't',
            'body': 'b',
            'status': 'failed',
            'is_read': false,
            'read_at': null,
            'created_at': '2026-11-19T03:40:00Z',
          },
          {
            'id': 'n-2',
            'notification_type': 'leave_request',
            'title': 't',
            'body': 'b',
            'status': 'sent',
            'is_read': true,
            'read_at': '2026-11-19T03:45:00Z',
            'created_at': '2026-11-19T03:30:00Z',
          },
        ],
        'meta': {'page': 1, 'per_page': 20, 'total': 2, 'total_pages': 1, 'unread_count': 1},
      };

      final page = (await repository.notifications()).dataOrNull!;

      expect([for (final r in page.items) r.isRead], [false, true]);
    });
  });

  group('mark one read', () {
    test('PUT /mobile/notifications/:id/read, with no body', () async {
      adapter.body = {
        'success': true,
        'data': {'id': 'n-1', 'is_read': true},
      };

      final result = await repository.markRead('n-1');

      expect(result.isSuccess, isTrue);
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, '/mobile/notifications/n-1/read');
      expect(adapter.lastRequest!.data, isNull);
    });

    test('an id is escaped in the path', () async {
      await repository.markRead('a/b c');
      expect(adapter.lastRequest!.path, '/mobile/notifications/a%2Fb%20c/read');
    });

    test('404 (someone else\'s, or gone): a failure, not a crash', () async {
      adapter
        ..status = 404
        ..body = {
          'success': false,
          'error': {'code': 'NOT_FOUND', 'message': 'not found'},
        };

      expect((await repository.markRead('n-x')).isFailure, isTrue);
    });
  });

  group('mark all read', () {
    test('PUT /mobile/notifications/read-all', () async {
      adapter.body = {
        'success': true,
        'data': {'updated': 3},
      };

      final result = await repository.markAllRead();

      expect(result.isSuccess, isTrue);
      expect(adapter.lastRequest!.method, 'PUT');
      expect(adapter.lastRequest!.path, '/mobile/notifications/read-all');
    });

    test('a server error: a failure', () async {
      adapter
        ..status = 500
        ..body = {'success': false};
      expect((await repository.markAllRead()).isFailure, isTrue);
    });
  });

  group('the unread count', () {
    test('GET /mobile/notifications/unread-count → count', () async {
      adapter.body = {
        'success': true,
        'data': {'count': 4},
      };

      final result = await repository.unreadCount();

      expect(result.dataOrNull, 4);
      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/mobile/notifications/unread-count');
    });

    test('zero is an answer', () async {
      adapter.body = {
        'success': true,
        'data': {'count': 0},
      };
      expect((await repository.unreadCount()).dataOrNull, 0);
    });

    test('an answer with no count in it is a failure, never "0 new"',
        () async {
      adapter.body = {'success': true, 'data': <String, dynamic>{}};
      final result = await repository.unreadCount();
      expect(result.isFailure, isTrue);

      adapter.body = {
        'success': true,
        'data': {'count': 'many'},
      };
      expect((await repository.unreadCount()).isFailure, isTrue);
    });

    test('no signal or a server error: a failure', () async {
      adapter
        ..status = 503
        ..body = {'success': false};
      final result = await repository.unreadCount();
      expect(result.failureOrNull, isA<Failure>());
    });
  });
}
