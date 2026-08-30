import '../../domain/entities/leave_attachment.dart';
import 'leave_parse.dart';

/// Reads one entry of `LeaveRequestResponse.attachments[]`
/// (leave-request-flutter.md §3.6).
class LeaveAttachmentModel {
  const LeaveAttachmentModel._();

  static LeaveAttachment? fromJson(Map<String, dynamic> json) {
    final url = LeaveJson.nonEmpty(json['url']);
    if (url == null) return null;
    return LeaveAttachment(
      id: LeaveJson.nonEmpty(json['id']),
      fileName:
          LeaveJson.nonEmpty(json['file_name']) ??
          LeaveJson.nonEmpty(json['original_name']) ??
          url,
      url: url,
      contentType: LeaveJson.nonEmpty(json['content_type']),
      size: LeaveJson.intOf(json['size']),
    );
  }
}
