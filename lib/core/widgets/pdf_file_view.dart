import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../theme/app_colors.dart';
import 'global_widgets.dart';

/// Shows the PDF file at a path, with [errorText] when the phone cannot
/// draw it. A provider so the tests can put a stand-in in its place: the
/// real viewer needs the phone's PDF renderer. Shared by the payslip and
/// the leave files.
final pdfFileViewProvider =
    Provider<Widget Function(String path, String errorText)>(
      (ref) =>
          (path, errorText) => PdfFileView(
            key: ValueKey(path),
            path: path,
            errorText: errorText,
          ),
    );

/// The PDF at [path], page under page, with pinch to zoom. Drawn by the
/// phone's own PDF renderer (`pdfx`).
class PdfFileView extends StatefulWidget {
  final String path;

  /// Said when the file is there but the renderer cannot open it.
  final String errorText;

  const PdfFileView({super.key, required this.path, required this.errorText});

  @override
  State<PdfFileView> createState() => _PdfFileViewState();
}

class _PdfFileViewState extends State<PdfFileView> {
  late final Future<PdfDocument> _document = PdfDocument.openFile(widget.path);
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: _document,
  );

  @override
  void dispose() {
    _controller.dispose();
    // The controller does not close the document. Until it is closed the
    // phone's renderer keeps the file open, and a deleted file's bytes stay
    // on disk.
    _document.then((document) => document.close(), onError: (_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              widget.errorText,
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
