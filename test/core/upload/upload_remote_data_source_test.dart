import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/upload/domain/upload_error_code.dart';
import 'package:next_on/core/upload/data/upload_remote_data_source.dart';
import 'package:next_on/core/upload/data/upload_repository_impl.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/domain/upload_rules.dart';
import 'package:next_on/core/upload/domain/uploaded_attachment.dart';

class _StubAdapter implements HttpClientAdapter {
  int status = 201;
  Object body = const <String, dynamic>{};
  RequestOptions? lastRequest;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
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

/// `POST /uploads`: what is sent, what comes back, and each refusal in the
/// words the user sees.
void main() {
  late _StubAdapter adapter;
  late UploadRemoteDataSourceImpl source;

  const photo = LocalFile(path: '/phone/IMG_0001.jpg', name: 'IMG_0001.jpg');
  const scan = LocalFile(path: '/phone/cert.pdf', name: 'cert.pdf');

  setUp(() {
    adapter = _StubAdapter();
    source = UploadRemoteDataSourceImpl(
      ApiClient(dio: Dio()..httpClientAdapter = adapter),
      // No real file on disk in a test: the same part, from bytes.
      readFile: (file, type) async => MultipartFile.fromBytes(
        [1, 2, 3],
        filename: file.name,
        contentType: type,
      ),
    );
  });

  void accepted() => adapter
    ..status = 201
    ..body = {
      'success': true,
      'data': {
        'url': 'https://files.nexton.work/t/uploads/abc_IMG_0001.jpg',
        'file_name': 't/uploads/abc_IMG_0001.jpg',
        'original_name': 'IMG_0001.jpg',
        'content_type': 'image/jpeg',
        'size': 312345,
      },
    };

  void refuse(int status, [String code = 'ERROR']) => adapter
    ..status = status
    ..body = {
      'success': false,
      'error': {'code': code, 'message': 'server english'},
    };

  FormData sent() => adapter.lastRequest!.data as FormData;

  test('POST /uploads, the file in the multipart field "file"', () async {
    accepted();
    await source.upload(photo);

    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.path, '/uploads');
    expect(sent().files.single.key, 'file');
    expect(sent().files.single.value.filename, 'IMG_0001.jpg');
  });

  test('the part carries its content type: image/jpeg, application/pdf',
      () async {
    accepted();
    await source.upload(photo);
    expect(sent().files.single.value.contentType.toString(), 'image/jpeg');

    await source.upload(scan);
    expect(
      sent().files.single.value.contentType.toString(),
      'application/pdf',
    );
  });

  test('the folder is sent when given, and left out when not', () async {
    accepted();
    await source.upload(photo, folder: UploadFolder.offsite);
    expect(Map.fromEntries(sent().fields), {'folder': 'offsite'});

    await source.upload(photo);
    expect(sent().fields, isEmpty);
  });

  test('a 201 is read into the uploaded file, as the server sent it',
      () async {
    accepted();
    final file = await source.upload(photo);

    expect(
      file,
      const UploadedAttachment(
        url: 'https://files.nexton.work/t/uploads/abc_IMG_0001.jpg',
        fileName: 't/uploads/abc_IMG_0001.jpg',
        originalName: 'IMG_0001.jpg',
        contentType: 'image/jpeg',
        size: 312345,
      ),
    );
  });

  Future<String?> tokenFor(int status, [String code = 'ERROR']) async {
    refuse(status, code);
    try {
      await source.upload(photo);
    } on Failure catch (failure) {
      return UploadErrorCode.tokenOf(failure);
    } on DioException {
      return null;
    }
    fail('expected a refusal');
  }

  test('413 (the server\'s body limit, code ERROR) is "over 5 MB", by status',
      () async {
    expect(await tokenFor(413), UploadErrorCode.tokenFileTooLarge);
  });

  test('FILE_TOO_LARGE is "over 5 MB"', () async {
    expect(
      await tokenFor(400, 'FILE_TOO_LARGE'),
      UploadErrorCode.tokenFileTooLarge,
    );
  });

  test('INVALID_REQUEST is "choose it again"', () async {
    expect(
      await tokenFor(400, 'INVALID_REQUEST'),
      UploadErrorCode.tokenInvalidFile,
    );
  });

  test('STORAGE_UNAVAILABLE, and a 404 (no storage, no route), are '
      '"contact HR"', () async {
    expect(
      await tokenFor(503, 'STORAGE_UNAVAILABLE'),
      UploadErrorCode.tokenStorageUnavailable,
    );
    expect(
      await tokenFor(404, 'NOT_FOUND'),
      UploadErrorCode.tokenStorageUnavailable,
    );
  });

  test('a 201 with no url, or no JSON object: "choose it again", not '
      'developer English', () async {
    adapter
      ..status = 201
      ..body = {
        'success': true,
        'data': {'file_name': 'x'},
      };
    expect(await _tokenOfCall(source, photo), UploadErrorCode.tokenInvalidFile);

    adapter.body = 'not json';
    expect(await _tokenOfCall(source, photo), UploadErrorCode.tokenInvalidFile);
  });

  test('a 500 is left to the shared network handling', () async {
    expect(await tokenFor(500, 'INTERNAL_ERROR'), isNull);
  });

  group('the size check, before anything is sent', () {
    late int size;
    late UploadRepositoryImpl repository;

    setUp(() {
      accepted();
      repository = UploadRepositoryImpl(
        remote: source,
        sizeOf: (_) async => size,
      );
    });

    test('over 5,000,000 bytes: refused as "over 5 MB", never sent', () async {
      size = UploadRules.maxBytes + 1;

      final result = await repository.upload(scan, folder: UploadFolder.leave);

      expect(
        UploadErrorCode.tokenOf(result.failureOrNull!),
        UploadErrorCode.tokenFileTooLarge,
      );
      expect(adapter.calls, 0);
    });

    test('the file gone before it is sent: "choose it again", not the '
        'raw error and its path', () async {
      final gone = UploadRepositoryImpl(
        remote: source,
        sizeOf: (path) => File(path).length(),
      );

      final result = await gone.upload(
        const LocalFile(path: '/nope/x.jpg', name: 'x.jpg'),
      );

      expect(
        UploadErrorCode.tokenOf(result.failureOrNull!),
        UploadErrorCode.tokenInvalidFile,
      );
      expect(adapter.calls, 0);
    });

    test('exactly 5,000,000 bytes: sent', () async {
      size = UploadRules.maxBytes;

      final result = await repository.upload(scan);

      expect(result.isSuccess, isTrue);
      expect(adapter.calls, 1);
    });

    test('the limit is under the server\'s 5 MiB body, with room for the '
        'multipart around it', () {
      expect(UploadRules.maxBytes, 5000000);
      expect(UploadRules.maxBytes, lessThan(5 * 1024 * 1024));
    });
  });
}

Future<String?> _tokenOfCall(
  UploadRemoteDataSourceImpl source,
  LocalFile file,
) async {
  try {
    await source.upload(file);
  } on Failure catch (failure) {
    return UploadErrorCode.tokenOf(failure);
  }
  return null;
}
