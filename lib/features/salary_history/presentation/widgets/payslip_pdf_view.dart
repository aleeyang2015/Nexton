import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Shows the PDF file at a path. A provider so the tests can put a stand-in
/// in its place: the real viewer needs the phone's PDF renderer.
final payslipPdfViewProvider = Provider<Widget Function(String path)>(
  (ref) =>
      (path) => PayslipPdfView(key: ValueKey(path), path: path),
);

/// The PDF at [path], page under page, with pinch to zoom. Drawn by the
/// phone's own PDF renderer (`pdfx`).
class PayslipPdfView extends StatefulWidget {
  final String path;

  const PayslipPdfView({super.key, required this.path});

  @override
  State<PayslipPdfView> createState() => _PayslipPdfViewState();
}

class _PayslipPdfViewState extends State<PayslipPdfView> {
  late final Future<PdfDocument> _document = PdfDocument.openFile(widget.path);
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: _document,
  );

  @override
  void dispose() {
    _controller.dispose();
    // The controller does not close the document. Until it is closed the
    // phone's renderer keeps the file open, and a deleted payslip's bytes
    // stay on disk.
    _document.then((document) => document.close(), onError: (_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PdfViewPinch(
      controller: _controller,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        pageLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        // The file was written but the renderer could not open it.
        errorBuilder: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: customText(
              l10n.payslipPdfMakeFailed,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 4,
            ),
          ),
        ),
      ),
    );
  }
}
