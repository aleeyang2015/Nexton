import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/uploaded_attachment.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/upload_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class UploadRepositoryImpl extends BaseRepository implements UploadRepository {
  final UploadRemoteDataSource _remote;

  UploadRepositoryImpl({required UploadRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<UploadedAttachment> upload(LocalFile file) =>
      guard(() => _remote.upload(file));
}
