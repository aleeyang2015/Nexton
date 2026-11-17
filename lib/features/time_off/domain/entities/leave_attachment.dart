import 'package:equatable/equatable.dart';

/// One file of a leave request (leave-request-flutter.md §3.6): one the
/// request already has, or one just uploaded from the form (#39).
class LeaveAttachment extends Equatable {
  final String? id;

  /// The server's storage key (`file_name`). Null when the server sent
  /// none: nothing is made up for it when the file goes back.
  final String? fileName;

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
    this.fileName,
    this.originalName,
    this.url,
    this.contentType,
    this.size,
  });

  /// The name to show: the original one, the storage key, or the end of
  /// the url.
  String get displayName =>
      originalName ?? fileName ?? url?.split('/').last ?? '';

  /// A photo. The content type decides when it says what the file is; the
  /// name only when it does not (none, or `application/octet-stream`).
  bool get isImage {
    final type = _type;
    if (type != null) return type.startsWith('image/');
    return _hasExtension(const ['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif']);
  }

  /// A PDF, by the same rule.
  bool get isPdf {
    final type = _type;
    if (type != null) return type == 'application/pdf';
    return _hasExtension(const ['pdf']);
  }

  /// The content type without its parameters (`; charset=…`), or null when
  /// it says nothing about the file.
  String? get _type {
    final raw = contentType?.split(';').first.trim().toLowerCase();
    if (raw == null || raw.isEmpty || raw == 'application/octet-stream') {
      return null;
    }
    return raw;
  }

  bool _hasExtension(List<String> extensions) {
    final name = displayName.toLowerCase();
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
