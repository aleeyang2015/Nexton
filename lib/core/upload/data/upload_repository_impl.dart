import '../../utils/base_repository.dart';
import '../../utils/result.dart';
import '../domain/local_file.dart';
import '../domain/uploaded_attachment.dart';
import '../domain/upload_repository.dart';
import 'upload_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class UploadRepositoryImpl extends BaseRepository implements UploadRepository {
  final UploadRemoteDataSource _remote;

  UploadRepositoryImpl({required UploadRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<UploadedAttachment> upload(LocalFile file) =>
      guard(() => _remote.upload(file));
}
