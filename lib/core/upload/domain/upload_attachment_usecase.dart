import '../../utils/base_usecase.dart';
import '../../utils/result.dart';
import 'local_file.dart';
import 'uploaded_attachment.dart';
import 'upload_repository.dart';

/// What to upload: the picked [file], and the [folder] it belongs in
/// (`UploadFolder`).
typedef UploadParams = ({LocalFile file, String? folder});

/// Uploads a picked file (`POST /uploads`): a leave document, an off-site
/// photo, a "forgot to scan" photo.
class UploadAttachmentUseCase
    implements BaseUseCase<UploadedAttachment, UploadParams> {
  final UploadRepository _repository;

  UploadAttachmentUseCase(this._repository);

  @override
  FutureResult<UploadedAttachment> call(UploadParams params) =>
      _repository.upload(params.file, folder: params.folder);
}
