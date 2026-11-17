import '../../utils/result.dart';
import 'local_file.dart';
import 'uploaded_attachment.dart';

/// Contract for the shared file upload (`POST /uploads`): leave documents,
/// off-site photos, "forgot to scan" photos. The implementation is in
/// `core/upload/data`.
abstract class UploadRepository {
  /// `POST /uploads` (multipart) — uploads [file] and returns the stored
  /// attachment metadata the backend echoes back.
  ///
  /// [folder] is where the server keeps it (`UploadFolder`). A file over
  /// `UploadRules.maxBytes` is refused without being sent.
  FutureResult<UploadedAttachment> upload(LocalFile file, {String? folder});
}
