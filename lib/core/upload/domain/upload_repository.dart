import '../../utils/result.dart';
import 'local_file.dart';
import 'uploaded_attachment.dart';

/// Contract for the generic file-upload endpoint the leave form's "attach
/// file" slot uses. The implementation lives in data/repositories and talks to
/// `POST /uploads`.
///
/// Feature-local for now because the leave form is the only caller; promote to
/// `core` if another feature needs it.
abstract class UploadRepository {
  /// `POST /uploads` (multipart) — uploads [file] and returns the stored
  /// attachment metadata the backend echoes back.
  ///
  /// [folder] is where the server keeps it (`UploadFolder`). A file over
  /// `UploadRules.maxBytes` is refused without being sent.
  FutureResult<UploadedAttachment> upload(LocalFile file, {String? folder});
}
