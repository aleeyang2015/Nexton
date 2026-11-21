import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/auth_interceptor.dart';
import 'package:next_on/features/notifications/data/datasources/device_remote_data_source.dart';

/// Answers every request with [status] and keeps the last one.
class _Recorder implements HttpClientAdapter {
  _Recorder(this.status);

  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}

/// The push sign-off at sign-out (#52, #71).
void main() {
  test('DELETE /mobile/devices/:id may renew an expired token: it carries no '
      'no-refresh flag (#71)', () async {
    final adapter = _Recorder(204);
    final source = DeviceRemoteDataSourceImpl(
      ApiClient(dio: Dio()..httpClientAdapter = adapter),
    );

    await source.unregister('dev 1');

    expect(adapter.last!.method, 'DELETE');
    expect(adapter.last!.path, endsWith('/mobile/devices/dev%201'));
    expect(adapter.last!.extra[AuthInterceptor.noRefreshFlag], isNot(true));
  });

  test('a 404 (already signed off) counts as done', () async {
    final source = DeviceRemoteDataSourceImpl(
      ApiClient(dio: Dio()..httpClientAdapter = _Recorder(404)),
    );

    await expectLater(source.unregister('dev-1'), completes);
  });
}
