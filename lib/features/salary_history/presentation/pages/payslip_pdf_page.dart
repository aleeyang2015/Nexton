import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/payslip_pdf_notifier.dart';
import '../widgets/payslip_pdf_view.dart';
import '../widgets/salary_error_block.dart';
import '../widgets/salary_history_copy.dart';

/// "ໃບເງິນເດືອນ (PDF)": one payslip's PDF, inside the App, with a Share
/// button. Opened by the payslip's id from the salary list or the payslip
/// page.
///
/// [payslipPdfNotifierProvider] fetches the PDF and keeps it in a temp
/// file while this page is open; the file is deleted when the page closes.
class PayslipPdfPage extends ConsumerWidget {
  final String payslipId;

  const PayslipPdfPage({super.key, required this.payslipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = payslipPdfNotifierProvider(payslipId);
    final pdf = ref.watch(provider);
    final path = pdf.isLoading ? null : pdf.valueOrNull;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              _PdfAppBar(
                title: l10n.payslipPdfTitle,
                onShare: path == null
                    ? null
                    : (origin) => _share(context, ref, origin),
              ),
              Expanded(
                child: pdf.isLoading
                    ? _Making(text: l10n.payslipPdfLoading)
                    : pdf.hasError
                    ? _Failed(
                        error: pdf.error,
                        onRetry: () => ref.read(provider.notifier).retry(),
                      )
                    : ref.watch(payslipPdfViewProvider)(path!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    final shared = await ref
        .read(payslipPdfNotifierProvider(payslipId).notifier)
        .share(origin: origin);
    if (!shared) AppToast.error(l10n.payslipPdfShareFailed);
  }
}

/// Back on the left, the title, and Share on the right once the PDF is
/// there.
class _PdfAppBar extends StatelessWidget {
  final String title;

  /// Null while there is nothing to share. Given where the button is, for
  /// the iPad's share sheet to point from.
  final void Function(Rect? origin)? onShare;

  const _PdfAppBar({required this.title, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onShare = this.onShare;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.salaryHistory),
            child: popBack(),
          ),
          widthBx(w: 8),
          Expanded(
            child: customText(
              title,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (onShare != null)
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: l10n.payslipPdfShare,
                icon: const Icon(Icons.ios_share, color: AppColors.primary),
                onPressed: () => onShare(_originOf(buttonContext)),
              ),
            ),
        ],
      ),
    );
  }

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// While the server makes the PDF.
class _Making extends StatelessWidget {
  final String text;

  const _Making({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          heightBx(h: 12),
          customText(text, color: AppColors.subTitle),
        ],
      ),
    );
  }
}

/// Why there is no PDF, with Retry where asking again can help.
class _Failed extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _Failed({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = SalaryHistoryCopy.pdfError(l10n, error);

    return SalaryErrorBlock(
      message: shown.message,
      onRetry: shown.canRetry ? onRetry : null,
    );
  }
}
