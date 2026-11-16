import '../../domain/entities/uploaded_attachment.dart';

/// Writes an [UploadedAttachment] back in the shape `POST /uploads` answered
/// with — the object request bodies embed unchanged (the leave request's
/// `attachments`, the time correction's `attachment_url`).
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
