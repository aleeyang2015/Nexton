import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../salary_history_providers.dart';
import '../services/payslip_pdf_files.dart';

/// One payslip's PDF, for the PDF page: fetched from
/// `GET /payroll/payslips/my/{id}/pdf`, written to a temp file, and the
/// file's path as the value.
///
/// Keyed by the payslip id and dropped when no page watches it, so a second
/// page for the same payslip (a double tap) shares the one request, and the
/// file is deleted as soon as the page closes: it holds salary data. A
/// failure is the [AsyncError]; nothing is written for it.
class PayslipPdfNotifier
    extends AutoDisposeFamilyAsyncNotifier<String, String> {
  @override
  Future<String> build(String arg) async {
    final files = ref.read(payslipPdfFilesProvider);
    var disposed = false;
    String? written;
    ref.onDispose(() {
      disposed = true;
      final path = written;
      if (path != null) files.delete(path);
    });

    final result = await ref.read(downloadPayslipPdfUseCaseProvider)(arg);
    final pdf = result.fold((failure) => throw failure, (pdf) => pdf);

    final path = await files.write(pdf);
    if (disposed) {
      // The page closed while the file was being written: nothing may stay
      // behind.
      await files.delete(path);
    } else {
      written = path;
    }
    return path;
  }

  /// Asks again after a failure. Does nothing while a load is running.
  Future<void> retry() async {
    if (state.isLoading) return;
    ref.invalidateSelf();
    await future.then<void>((_) {}, onError: (_) {});
  }

  bool _sharing = false;

  /// Opens the share sheet with the loaded PDF. False when there is no file
  /// yet, or the share sheet could not be opened. A second tap while the
  /// sheet is open does nothing (and is not a failure).
  Future<bool> share({Rect? origin}) async {
    final path = state.valueOrNull;
    if (path == null || state.isLoading) return false;
    if (_sharing) return true;
    _sharing = true;
    try {
      await ref.read(payslipPdfFilesProvider).share(path, origin: origin);
      return true;
    } catch (_) {
      return false;
    } finally {
      _sharing = false;
    }
  }
}

final payslipPdfNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<PayslipPdfNotifier, String, String>(PayslipPdfNotifier.new);
