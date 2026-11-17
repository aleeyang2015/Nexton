import '../../domain/entities/leave_attachment.dart';
import 'leave_parse.dart';

/// Reads one entry of `LeaveRequestResponse.attachments[]`
/// (leave-request-flutter.md §3.6).
class LeaveAttachmentModel {
  const LeaveAttachmentModel._();

  ///
  /// A file with no `url` is kept (the server stores one by `file_name`
  /// alone): it is shown as text and sent back on an edit. Only an entry
  /// with neither a name nor a url is dropped.
  static LeaveAttachment? fromJson(Map<String, dynamic> json) {
    final url = LeaveJson.nonEmpty(json['url']);
    final originalName = LeaveJson.nonEmpty(json['original_name']);
    final fileName =
        LeaveJson.nonEmpty(json['file_name']) ?? originalName ?? url;
    if (fileName == null) return null;
    return LeaveAttachment(
      id: LeaveJson.nonEmpty(json['id']),
      fileName: fileName,
      originalName: originalName,
      url: url,
      contentType: LeaveJson.nonEmpty(json['content_type']),
      size: LeaveJson.intOf(json['size']),
    );
  }

  /// The object a create or an edit sends for this file: the upload's keys,
  /// `url` left out when it has none.
  static Map<String, dynamic> toJson(LeaveAttachment file) => {
    if (file.url != null) 'url': file.url,
    'file_name': file.fileName,
    if (file.originalName != null) 'original_name': file.originalName,
    if (file.contentType != null) 'content_type': file.contentType,
    if (file.size != null) 'size': file.size,
  };
}
