import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/local_file.dart';

/// Thin wrapper around the `file_picker` plugin so the notifier depends on a
/// mockable seam, not the platform channel directly.
class AttachmentPicker {
  const AttachmentPicker();

  /// File extensions the upload API accepts: images, PDFs, Word and Excel
  /// documents. Lower-case, no leading dot — the shape `file_picker` expects.
  static const List<String> allowedExtensions = [
    // Images
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp',
    // PDF
    'pdf',
    // Word
    'doc', 'docx',
    // Excel
    'xls', 'xlsx',
  ];

  /// Opens the system file chooser filtered to [allowedExtensions] and returns
  /// the pick, or null when the user backs out (or the entry has no on-disk
  /// path). A leave request carries a single attachment, so only one file is
  /// offered.
  Future<LocalFile?> pickAttachment() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final file = result?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    return LocalFile(path: path, name: file.name);
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => const AttachmentPicker(),
);
