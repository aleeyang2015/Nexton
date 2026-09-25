import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around `file_picker`'s save dialog, so the notifier depends
/// on a mockable seam rather than the platform channel — same split as
/// `PayslipPdfSaver`.
class AttachmentFileSaver {
  const AttachmentFileSaver();

  /// Offers [bytes] for saving under [fileName] and returns the chosen path,
  /// or null when the user backs out of the dialog.
  Future<String?> save(Uint8List bytes, {required String fileName}) =>
      FilePicker.saveFile(fileName: fileName, bytes: bytes);
}

final attachmentFileSaverProvider = Provider<AttachmentFileSaver>(
  (ref) => const AttachmentFileSaver(),
);
