import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/payslip_pdf.dart';

/// Where an opened payslip PDF lives while its page is open, and how it is
/// shared.
///
/// Each open gets its own folder under `<temp>/payslips/`, holding one file
/// under the server's name (`payslip-EMP-002-2026-09.pdf`), so the share
/// sheet offers that name. The page deletes the folder when it closes: the
/// file holds salary data. Folders left by an App that was killed while the
/// page was open are cleared the next time a PDF is opened.
///
/// A seam for the tests, as `PayslipPdfSaver` was: the plugins need a
/// platform.
class PayslipPdfFiles {
  final Future<Directory> Function() _tempDir;

  PayslipPdfFiles({Future<Directory> Function()? tempDir})
    : _tempDir = tempDir ?? getTemporaryDirectory;

  /// The folders of PDFs open now, in this run of the App. Anything else in
  /// `payslips/` is left over and is cleared.
  final Set<String> _open = {};
  int _count = 0;

  /// Writes [pdf] to a folder of its own and returns the file's path.
  Future<String> write(PayslipPdf pdf) async {
    final root = Directory(_join((await _tempDir()).path, 'payslips'));
    await _clearLeftovers(root);

    final folder = Directory(
      _join(root.path, '${DateTime.now().microsecondsSinceEpoch}-${_count++}'),
    );
    await folder.create(recursive: true);
    _open.add(folder.path);

    final file = File(_join(folder.path, safeFileName(pdf.fileName)));
    await file.writeAsBytes(pdf.bytes, flush: true);
    return file.path;
  }

  /// Deletes the file at [path] and its folder. Nothing happens when they
  /// are already gone.
  Future<void> delete(String path) async {
    final folder = File(path).parent;
    _open.remove(folder.path);
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } on FileSystemException {
      // Already gone, or the OS cleared its temp folder: nothing to keep.
    }
  }

  /// Opens the phone's share sheet with the PDF at [path]. [origin] is
  /// where the sheet points from on an iPad.
  Future<void> share(String path, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _clearLeftovers(Directory root) async {
    if (!await root.exists()) return;
    await for (final entry in root.list()) {
      if (_open.contains(entry.path)) continue;
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        // A leftover the OS is clearing at the same time: fine either way.
      }
    }
  }

  static String _join(String folder, String name) =>
      '$folder${Platform.pathSeparator}$name';

  /// [name] as a plain file name: no folders, nothing but letters, digits,
  /// `-`, `_` and `.`, ending in `.pdf`. A name from a header must not
  /// write outside the folder (`../../x`).
  static String safeFileName(String name) {
    var base = name.replaceAll('\\', '/').split('/').last;
    base = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    base = base.replaceAll(RegExp(r'^\.+'), '');
    if (base.isEmpty) base = 'payslip';
    if (!base.toLowerCase().endsWith('.pdf')) base = '$base.pdf';
    return base;
  }
}

final payslipPdfFilesProvider = Provider<PayslipPdfFiles>(
  (ref) => PayslipPdfFiles(),
);
