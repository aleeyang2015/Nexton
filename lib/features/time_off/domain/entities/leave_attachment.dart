import 'package:equatable/equatable.dart';

/// One file attached to a leave request (leave-request-flutter.md §3.6).
///
/// The app only ever displays these as links — there is no in-app file
/// picker, so a request is never created with attachments from here.
class LeaveAttachment extends Equatable {
  final String? id;
  final String fileName;
  final String url;
  final String? contentType;
  final int? size;

  const LeaveAttachment({
    this.id,
    required this.fileName,
    required this.url,
    this.contentType,
    this.size,
  });

  @override
  List<Object?> get props => [id, fileName, url, contentType, size];
}
