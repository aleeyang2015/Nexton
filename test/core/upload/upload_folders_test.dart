import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/domain/upload_repository.dart';
import 'package:next_on/core/upload/domain/uploaded_attachment.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/presentation/providers/offsite_photo_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_attachment_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/services/attachment_picker.dart';

class _RecordingUploads implements UploadRepository {
  final List<String?> folders = [];

  @override
  FutureResult<UploadedAttachment> upload(
    LocalFile file, {
    String? folder,
  }) async {
    folders.add(folder);
    return const Result.success(
      UploadedAttachment(url: 'u', fileName: 'f', originalName: 'o'),
    );
  }
}

class _PicksOne extends AttachmentPicker {
  const _PicksOne(this.file);

  final LocalFile file;

  @override
  Future<LocalFile?> pickAttachment({
    List<String> extensions = AttachmentPicker.allowedExtensions,
  }) async => file;
}

/// Each feature sends its upload with its own `folder`, so the server keeps
/// leave documents, off-site proof and "forgot to scan" photos apart.
void main() {
  late Directory temp;
  late LocalFile photo;
  late _RecordingUploads uploads;
  late ProviderContainer container;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('upload_folders_test');
    final path = '${temp.path}/IMG_0001.jpg';
    await File(path).writeAsBytes([1, 2, 3]);
    photo = LocalFile(path: path, name: 'IMG_0001.jpg');
    uploads = _RecordingUploads();
    container = ProviderContainer(
      overrides: [
        uploadRepositoryProvider.overrideWithValue(uploads),
        attachmentPickerProvider.overrideWithValue(_PicksOne(photo)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await temp.delete(recursive: true);
  });

  test('a leave document: leave', () async {
    await container
        .read(leaveRequestFormNotifierProvider(null).notifier)
        .addFile(photo);
    expect(uploads.folders, ['leave']);
  });

  test('an off-site photo: offsite', () async {
    final sub = container.listen(offsitePhotoNotifierProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(offsitePhotoNotifierProvider.notifier).upload(photo);
    expect(uploads.folders, ['offsite']);
  });

  test('a "forgot to scan" photo: correction', () async {
    final provider = timeCorrectionAttachmentNotifierProvider;
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.notifier).upload(photo);
    expect(uploads.folders, ['correction']);
  });

  test('a file gone before the off-site or "forgot to scan" check: no crash, '
      'the upload says what is wrong', () async {
    const gone = LocalFile(path: '/nope/x.jpg', name: 'x.jpg');
    final offsite = container.listen(offsitePhotoNotifierProvider, (_, _) {});
    addTearDown(offsite.close);
    final correction = container.listen(
      timeCorrectionAttachmentNotifierProvider,
      (_, _) {},
    );
    addTearDown(correction.close);

    await container.read(offsitePhotoNotifierProvider.notifier).upload(gone);
    await container
        .read(timeCorrectionAttachmentNotifierProvider.notifier)
        .upload(gone);

    expect(uploads.folders, ['offsite', 'correction']);
  });
}
