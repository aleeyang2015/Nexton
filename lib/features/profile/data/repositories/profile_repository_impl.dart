import 'dart:io';

import '../../../../core/errors/failure.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../../../../core/upload/domain/upload_rules.dart';
import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/employee_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_photo_error_code.dart';
import '../datasources/profile_remote_data_source.dart';

/// How big the file at a path is, in bytes. A seam so tests need no file.
typedef FileSizeOf = Future<int> Function(String path);

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class ProfileRepositoryImpl extends BaseRepository
    implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final FileSizeOf _sizeOf;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remote,
    FileSizeOf? sizeOf,
  }) : _remote = remote,
       _sizeOf = sizeOf ?? _sizeOnDisk;

  static Future<int> _sizeOnDisk(String path) => File(path).length();

  /// A name the profile photo may have: `.jpg`, `.jpeg` or `.png`.
  static bool isPhotoName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  @override
  FutureResult<EmployeeProfile> myProfile() => guard(() => _remote.myProfile());

  /// The size check every upload gets (#38's rule): a photo over
  /// [UploadRules.maxBytes] is refused here and never sent. Camera and
  /// gallery photos are not shrunk (no package for it), so a big gallery
  /// photo or image file ends here.
  @override
  FutureResult<String> uploadMyPhoto(String employeeId, LocalFile file) =>
      guard(() async {
        // JPEG and PNG only: a HEIC, WEBP or GIF from the gallery would be
        // stored as an image HR's browser may not show.
        if (!isPhotoName(file.name)) {
          throw const Failure.validation(
            message: ProfilePhotoErrorCode.tokenNotImage,
          );
        }
        try {
          if (await _sizeOf(file.path) > UploadRules.maxBytes) {
            throw const Failure.validation(
              message: ProfilePhotoErrorCode.tokenTooLarge,
            );
          }
          return await _remote.uploadPhoto(employeeId, file);
        } on FileSystemException {
          // The picked file is gone or unreadable: choose another.
          throw const Failure.validation(
            message: ProfilePhotoErrorCode.tokenNotImage,
          );
        }
      });
}
