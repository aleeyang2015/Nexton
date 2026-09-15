import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payslip_pdf.dart';

/// Thin wrapper around `file_picker`'s save dialog so the notifier depends on
/// a mockable seam, not the platform channel directly — same split as
/// `AttachmentPicker`. On Android and iOS the plugin writes [PayslipPdf.bytes]
/// to whatever location the user picks in the system dialog.
class PayslipPdfSaver {
  const PayslipPdfSaver();

  /// Offers [pdf] for saving under [fileName] and returns the chosen path, or
  /// null when the user backs out of the dialog.
  Future<String?> save(PayslipPdf pdf, {required String fileName}) {
    return FilePicker.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: pdf.bytes,
    );
  }
}

final payslipPdfSaverProvider = Provider<PayslipPdfSaver>(
  (ref) => const PayslipPdfSaver(),
);
