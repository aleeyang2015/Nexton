import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/api_paths.dart';
import 'package:next_on/features/auth/data/datasources/auth_remote_data_source.dart';

/// The server's logout (#56): `POST /auth/logout` with the refresh token in
/// the body, bounded by the limit it is given.
void main() {
  test('POSTs the refresh token, within the limit', () async {
    final adapter = _Stub();
    final source = AuthRemoteDataSourceImpl(
      ApiClient(dio: Dio()..httpClientAdapter = adapter),
    );

    await source.logout('refresh-1', timeout: const Duration(seconds: 5));

    final sent = adapter.last!;
    expect(sent.method, 'POST');
    expect(sent.path, ApiPaths.logout);
    expect(sent.data, {'refresh_token': 'refresh-1'});
    expect(sent.sendTimeout, const Duration(seconds: 5));
    expect(sent.receiveTimeout, const Duration(seconds: 5));
  });
}

class _Stub implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    // `204`, no body.
    return ResponseBody.fromString(jsonEncode(null), 204);
  }

  @override
  void close({bool force = false}) {}
}
