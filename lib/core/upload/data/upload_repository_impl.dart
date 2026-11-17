import 'dart:io';

import '../../errors/failure.dart';
import '../../utils/base_repository.dart';
import '../../utils/result.dart';
import '../domain/local_file.dart';
import '../domain/upload_repository.dart';
import '../domain/upload_error_code.dart';
import '../domain/upload_rules.dart';
import '../domain/uploaded_attachment.dart';
import 'upload_remote_data_source.dart';

/// How big the file at a path is, in bytes. A seam so tests need no file.
typedef FileSizeOf = Future<int> Function(String path);

/// Wraps the remote source in [Result], via [BaseRepository.guard], after
/// the one size check every upload gets: a file over
/// [UploadRules.maxBytes] is refused here and never sent.
class UploadRepositoryImpl extends BaseRepository implements UploadRepository {
  final UploadRemoteDataSource _remote;
  final FileSizeOf _sizeOf;

  UploadRepositoryImpl({
    required UploadRemoteDataSource remote,
    FileSizeOf? sizeOf,
  }) : _remote = remote,
       _sizeOf = sizeOf ?? _sizeOnDisk;

  static Future<int> _sizeOnDisk(String path) => File(path).length();

  @override
  FutureResult<UploadedAttachment> upload(LocalFile file, {String? folder}) =>
      guard(() async {
        try {
          if (await _sizeOf(file.path) > UploadRules.maxBytes) {
            throw const Failure.validation(
              message: UploadErrorCode.tokenFileTooLarge,
            );
          }
          return await _remote.upload(file, folder: folder);
        } on FileSystemException {
          // The picked file is gone or unreadable (cleared by the phone
          // between the pick and the send): pick it again.
          throw const Failure.validation(
            message: UploadErrorCode.tokenInvalidFile,
          );
        }
      });
}
