import 'package:equatable/equatable.dart';

/// One file of a leave request (leave-request-flutter.md §3.6): one the
/// request already has, or one just uploaded from the form (#39).
class LeaveAttachment extends Equatable {
  final String? id;

  /// The server's storage key (`file_name`).
  final String fileName;

  /// The name the file had on the phone or computer it came from.
  final String? originalName;

  /// Where it can be opened (a plain storage URL, no token). Null for a file
  /// the server kept without one: shown as plain text, and sent back as it
  /// is when the files change, so an edit never drops it.
  final String? url;
  final String? contentType;
  final int? size;

  const LeaveAttachment({
    this.id,
    required this.fileName,
    this.originalName,
    this.url,
    this.contentType,
    this.size,
  });

  /// The name to show: the original one when known.
  String get displayName => originalName ?? fileName;

  /// A photo, by its type or, failing that, its name.
  bool get isImage {
    final type = contentType?.toLowerCase();
    if (type != null && type.startsWith('image/')) return true;
    return _hasExtension(const ['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif']);
  }

  /// A PDF, by its type or, failing that, its name.
  bool get isPdf {
    final type = contentType?.toLowerCase();
    if (type == 'application/pdf') return true;
    return _hasExtension(const ['pdf']);
  }

  bool _hasExtension(List<String> extensions) {
    final name = (originalName ?? fileName).toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot >= 0 && extensions.contains(name.substring(dot + 1));
  }

  @override
  List<Object?> get props => [
    id,
    fileName,
    originalName,
    url,
    contentType,
    size,
  ];
}
