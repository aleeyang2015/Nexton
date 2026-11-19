import '../domain/uploaded_attachment.dart';

/// Writes an [UploadedAttachment] back in the shape `POST /uploads` answered
/// with — the object request bodies embed unchanged (the leave request's and
/// the off-site scan's `attachments`). The time correction's `attachment_url`
/// is not one of them: it takes the file's URL as text.
class UploadedAttachmentModel {
  const UploadedAttachmentModel._();

  static Map<String, dynamic> toJson(UploadedAttachment attachment) => {
    'url': attachment.url,
    'file_name': attachment.fileName,
    'original_name': attachment.originalName,
    if (attachment.contentType != null) 'content_type': attachment.contentType,
    if (attachment.size != null) 'size': attachment.size,
  };
}
