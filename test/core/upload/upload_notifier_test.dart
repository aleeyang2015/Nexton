import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/upload/data/upload_error_code.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/domain/upload_repository.dart';
import 'package:next_on/core/upload/domain/uploaded_attachment.dart';
import 'package:next_on/core/upload/presentation/upload_notifier.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';

class _Uploads implements UploadRepository {
  Result<UploadedAttachment> answer = const Result.success(_kept);
  Completer<void>? hold;
  final List<({String name, String? folder})> calls = [];

  @override
  FutureResult<UploadedAttachment> upload(
    LocalFile file, {
    String? folder,
  }) async {
    calls.add((name: file.name, folder: folder));
    final reply = answer;
    final h = hold;
    hold = null;
    await h?.future;
    return reply;
  }
}

const _kept = UploadedAttachment(
  url: 'https://files/abc.jpg',
  fileName: 'abc.jpg',
  originalName: 'IMG_0001.jpg',
);

/// One upload slot, from the pick to the file the server kept.
void main() {
  const photo = LocalFile(path: '/phone/IMG_0001.jpg', name: 'IMG_0001.jpg');
  late _Uploads uploads;
  late ProviderContainer container;
  final provider = uploadNotifierProvider('offsite');

  setUp(() {
    uploads = _Uploads();
    container = ProviderContainer(
      overrides: [uploadRepositoryProvider.overrideWithValue(uploads)],
    );
    container.listen(provider, (_, _) {});
  });

  tearDown(() => container.dispose());

  UploadState state() => container.read(provider);
  UploadNotifier notifier() => container.read(provider.notifier);

  test('uploading, then done with the file the server kept, in its folder',
      () async {
    final slow = Completer<void>();
    uploads.hold = slow;

    final going = notifier().upload(photo);
    expect(state().uploading, isTrue);
    slow.complete();
    await going;

    expect(state(), const UploadState(file: _kept));
    expect(uploads.calls.single.folder, 'offsite');
  });

  test('a second upload while one is on its way does nothing', () async {
    final slow = Completer<void>();
    uploads.hold = slow;

    final first = notifier().upload(photo);
    await notifier().upload(photo);
    slow.complete();
    await first;

    expect(uploads.calls, hasLength(1));
  });

  test('a failure is kept, with the file from before', () async {
    await notifier().upload(photo);
    uploads.answer = const Result.failure(
      Failure.validation(message: UploadErrorCode.tokenFileTooLarge),
    );

    await notifier().upload(photo);

    expect(state().file, _kept);
    expect(
      UploadErrorCode.tokenOf(state().failure!),
      UploadErrorCode.tokenFileTooLarge,
    );
    expect(state().uploading, isFalse);
  });

  test('from the sheet: a file uploads, a refusal says "allow it in '
      'settings", a back-out changes nothing', () async {
    await notifier().accept(const CaptureCancelled());
    expect(state(), const UploadState());

    await notifier().accept(const CaptureDenied());
    expect(
      UploadErrorCode.tokenOf(state().failure!),
      UploadErrorCode.tokenPermissionDenied,
    );
    expect(uploads.calls, isEmpty);

    await notifier().accept(const Captured(photo));
    expect(state(), const UploadState(file: _kept));
  });
}
