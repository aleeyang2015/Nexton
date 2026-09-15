import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payslip.dart';
import '../../salary_history_providers.dart';
import '../services/payslip_pdf_saver.dart';

/// Fetches one payslip's PDF (`GET /payslips/my/{id}/pdf`) and hands the
/// bytes to the system save dialog. Keyed by payslip id so the history
/// card's button and the detail page's save icon share one in-flight state.
///
/// The value is the saved path once a download completed, or null when
/// nothing has been saved yet (including a dialog the user backed out of).
/// A failed download surfaces as [AsyncError]; the page toasts it.
class PayslipPdfNotifier
    extends AutoDisposeFamilyAsyncNotifier<String?, String> {
  bool _disposed = false;

  @override
  Future<String?> build(String arg) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return null;
  }

  /// [payslip] must be the payslip this notifier is keyed by — its period
  /// names the file when the server doesn't.
  Future<void> download(Payslip payslip) async {
    assert(payslip.id == arg, 'download() called with a different payslip');
    if (state.isLoading) return;

    // Keep the download alive while the card is collapsed or the page popped
    // mid-flight; the link is released once the state settles.
    final link = ref.keepAlive();
    state = const AsyncValue<String?>.loading();

    final result = await ref.read(downloadPayslipPdfUseCaseProvider)(payslip.id);

    final next = await result.fold(
      (failure) async => AsyncValue<String?>.error(failure, StackTrace.current),
      (pdf) async {
        final path = await ref
            .read(payslipPdfSaverProvider)
            .save(pdf, fileName: pdf.fileName ?? _defaultFileName(payslip));
        return AsyncValue<String?>.data(path);
      },
    );

    if (!_disposed) state = next;
    link.close();
  }

  /// "payslip-2026-08.pdf".
  static String _defaultFileName(Payslip payslip) =>
      'payslip-${payslip.year}-${payslip.month.toString().padLeft(2, '0')}.pdf';
}

final payslipPdfNotifierProvider =
    AsyncNotifierProvider.autoDispose
        .family<PayslipPdfNotifier, String?, String>(PayslipPdfNotifier.new);
