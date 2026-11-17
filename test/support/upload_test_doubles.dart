import 'dart:async';

import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/domain/upload_repository.dart';
import 'package:next_on/core/upload/domain/uploaded_attachment.dart';
import 'package:next_on/core/utils/result.dart';

/// `POST /uploads` in memory: answers [answer] (by default the file back,
/// stored under `uploads/<name>`), records each call, and waits for [hold]
/// when set (taken by the call that sees it).
class FakeUploads implements UploadRepository {
  Result<UploadedAttachment>? answer;
  Completer<void>? hold;
  final List<({String name, String? folder})> calls = [];

  @override
  FutureResult<UploadedAttachment> upload(
    LocalFile file, {
    String? folder,
  }) async {
    calls.add((name: file.name, folder: folder));
    final reply =
        answer ??
        Result.success(
          UploadedAttachment(
            url: 'https://files.nexton.work/uploads/${file.name}',
            fileName: 'uploads/${file.name}',
            originalName: file.name,
            contentType: 'image/jpeg',
            size: 1234,
          ),
        );
    final h = hold;
    hold = null;
    await h?.future;
    return reply;
  }
}
