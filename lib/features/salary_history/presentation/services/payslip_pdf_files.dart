import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/temp_share_files.dart';

import '../../domain/entities/payslip_pdf.dart';

/// Where an opened payslip PDF lives while its page is open, and how it is
/// shared: the shared [TempShareFiles], set up for payslips. Folders under
/// `<temp>/payslips/`, every name ending in `.pdf`, and Android's shared
/// `payslip….pdf` copies cleared at the next open. The page deletes the
/// folder when it closes: the file holds salary data.
class PayslipPdfFiles extends TempShareFiles {
  PayslipPdfFiles({super.tempDir})
    : super(
        folderName: 'payslips',
        fallbackName: 'payslip',
        forcedExtension: 'pdf',
        sharedCopyPrefix: 'payslip',
      );

  /// Writes [pdf] to a folder of its own and returns the file's path.
  Future<String> write(PayslipPdf pdf) => writeBytes(pdf.bytes, pdf.fileName);

  /// Opens the phone's share sheet with the PDF at [path].
  @override
  Future<void> share(String path, {String? mimeType, Rect? origin}) => super
      .share(path, mimeType: mimeType ?? 'application/pdf', origin: origin);

  /// [name] as a payslip file name (see [TempShareFiles.safeName]).
  static String safeFileName(String name) => TempShareFiles.safeName(
    name,
    fallback: 'payslip',
    forcedExtension: 'pdf',
  );
}

final payslipPdfFilesProvider = Provider<PayslipPdfFiles>(
  (ref) => PayslipPdfFiles(),
);
