import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/local_file.dart';
import '../entities/uploaded_attachment.dart';
import '../repositories/upload_repository.dart';

/// Uploads the file picked in the leave form's "attach file" slot
/// (`POST /uploads`).
class UploadAttachmentUseCase
    implements BaseUseCase<UploadedAttachment, LocalFile> {
  final UploadRepository _repository;

  UploadAttachmentUseCase(this._repository);

  @override
  FutureResult<UploadedAttachment> call(LocalFile file) =>
      _repository.upload(file);
}
