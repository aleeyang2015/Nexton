import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/features/profile/data/datasources/profile_photo_error_code.dart';
import 'package:next_on/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:next_on/features/profile/data/repositories/profile_repository_impl.dart';

/// The photo change (#59): `PUT /core_hr/employees/:id/photo`, one `photo`
/// part with an `image/…` type; the new URL back.
void main() {
  late _Stub adapter;
  late ProfileRemoteDataSourceImpl source;
  late List<DioMediaType> partTypes;

  setUp(() {
    adapter = _Stub();
    partTypes = [];
    source = ProfileRemoteDataSourceImpl(
      ApiClient(dio: Dio()..httpClientAdapter = adapter),
      readPart: (file, type) async {
        partTypes.add(type);
        return MultipartFile.fromBytes(
          [1, 2, 3],
          filename: file.name,
          contentType: type,
        );
      },
    );
  });

  const jpg = LocalFile(path: '/tmp/me.jpg', name: 'me.jpg');

  test(
    'PUTs one photo part, as an image, to the employee\'s own path',
    () async {
      final url = await source.uploadPhoto('emp 1', jpg);

      final sent = adapter.last!;
      expect(sent.method, 'PUT');
      expect(sent.path, '/core_hr/employees/emp%201/photo');
      final form = sent.data as FormData;
      expect(form.files.single.key, 'photo');
      expect(form.files.single.value.contentType.toString(), 'image/jpeg');
      expect(url, 'https://files.nexton.work/photos/new.jpg');
    },
  );

  test('a PNG goes as image/png', () async {
    await source.uploadPhoto(
      'emp-1',
      const LocalFile(path: '/tmp/me.PNG', name: 'me.PNG'),
    );
    expect(partTypes.single.toString(), 'image/png');
  });

  test('413 (over the body limit): too large', () async {
    adapter.reply = (
      413,
      {
        'success': false,
        'error': {'code': 'ERROR'},
      },
    );
    await expectLater(
      source.uploadPhoto('emp-1', jpg),
      throwsA(
        const Failure.validation(message: ProfilePhotoErrorCode.tokenTooLarge),
      ),
    );
  });

  test('INVALID_REQUEST (no file, not an image): not a photo', () async {
    adapter.reply = (
      400,
      {
        'success': false,
        'error': {'code': 'INVALID_REQUEST', 'message': 'not an image'},
      },
    );
    await expectLater(
      source.uploadPhoto('emp-1', jpg),
      throwsA(
        const Failure.validation(message: ProfilePhotoErrorCode.tokenNotImage),
      ),
    );
  });

  test('another refusal is left to the shared handling', () async {
    adapter.reply = (
      403,
      {
        'success': false,
        'error': {'code': 'FORBIDDEN', 'message': 'no'},
      },
    );
    await expectLater(
      source.uploadPhoto('emp-1', jpg),
      throwsA(isA<DioException>()),
    );
  });

  test('a 200 that is not the answer (a Wi-Fi login page): a server '
      'error, not the photo\'s fault', () async {
    adapter.reply = (200, {'success': true});
    await expectLater(
      source.uploadPhoto('emp-1', jpg),
      throwsA(isA<ServerFailure>()),
    );
  });

  group('the size check, on the phone', () {
    test('over 5,000,000 bytes: refused, never sent', () async {
      final repository = ProfileRepositoryImpl(
        remote: source,
        sizeOf: (_) async => 5000001,
      );
      final result = await repository.uploadMyPhoto('emp-1', jpg);
      expect(
        result.failureOrNull,
        const Failure.validation(message: ProfilePhotoErrorCode.tokenTooLarge),
      );
      expect(adapter.last, isNull);
    });

    test(
      'a HEIC, WEBP or GIF from the gallery: "not a photo", never sent',
      () async {
        final repository = ProfileRepositoryImpl(
          remote: source,
          sizeOf: (_) async => 1000,
        );
        for (final name in [
          'IMG_0001.HEIC',
          'x.webp',
          'x.gif',
          'noextension',
        ]) {
          final result = await repository.uploadMyPhoto(
            'emp-1',
            LocalFile(path: '/tmp/$name', name: name),
          );
          expect(
            result.failureOrNull,
            const Failure.validation(
              message: ProfilePhotoErrorCode.tokenNotImage,
            ),
            reason: name,
          );
        }
        expect(adapter.last, isNull);
      },
    );

    test('exactly 5,000,000 bytes: sent', () async {
      final repository = ProfileRepositoryImpl(
        remote: source,
        sizeOf: (_) async => 5000000,
      );
      final result = await repository.uploadMyPhoto('emp-1', jpg);
      expect(result.dataOrNull, 'https://files.nexton.work/photos/new.jpg');
    });
  });
}

class _Stub implements HttpClientAdapter {
  RequestOptions? last;
  (int, Map<String, dynamic>) reply = (
    200,
    {'profile_photo_url': 'https://files.nexton.work/photos/new.jpg'},
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final (status, body) = reply;
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
