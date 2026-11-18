import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/network/auth_interceptor.dart';
import 'package:next_on/features/app_gate/app_gate_providers.dart';
import 'package:next_on/features/app_gate/data/datasources/app_info_remote_data_source.dart';

/// The version check (#57): public, no token, a 5 s limit.
void main() {
  test(
    'sends the platform and the version, with no token, within 5 s',
    () async {
      final adapter = _Stub();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dio = container.read(appInfoClientProvider)
        ..httpClientAdapter = adapter;

      final info = await AppInfoRemoteDataSourceImpl(
        dio,
      ).appInfo(platform: 'android', version: '1.0.1');

      final sent = adapter.last!;
      expect(sent.path, AppInfoRemoteDataSource.path);
      expect(sent.queryParameters, {'platform': 'android', 'version': '1.0.1'});
      expect(sent.headers[AppConstants.authorizationHeader], isNull);
      expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);
      expect(sent.sendTimeout, const Duration(seconds: 5));
      expect(sent.receiveTimeout, const Duration(seconds: 5));
      expect(info.forceUpdate, isTrue);
    },
  );
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
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'force_update': true, 'is_maintenance': false},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
