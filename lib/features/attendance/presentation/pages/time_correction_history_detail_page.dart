import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../providers/time_correction_detail_notifier.dart';
import '../widgets/time_correction_approval_workflow.dart';
import '../widgets/time_correction_detail_cards.dart';

/// "ລາຍລະອຽດຄຳຮ້ອງ" — one time-correction request in full, from
/// `GET /attendance/correction-requests/:id`, with a cancel action while it
/// is still pending. Pops with `true` once the request is cancelled, so the
/// history list can reload.
class TimeCorrectionHistoryDetailPage extends ConsumerWidget {
  final String id;

  const TimeCorrectionHistoryDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = timeCorrectionDetailNotifierProvider(id);
    final state = ref.watch(provider);
    final detail = state.detail;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: ref.read(provider.notifier).refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 32),
                    children: [
                      if (detail.hasValue)
                        _Body(
                          id: id,
                          detail: detail.requireValue,
                          cancelling: state.cancelling,
                          downloading: state.downloading,
                        )
                      else if (detail.hasError)
                        _LoadFailed(
                          message: l10n.timeCorrectionDetailLoadFailed,
                          onRetry: ref.read(provider.notifier).refresh,
                        )
                      else
                        const _Loading(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final String id;
  final TimeCorrectionDetail detail;
  final bool cancelling;
  final bool downloading;

  const _Body({
    required this.id,
    required this.detail,
    required this.cancelling,
    required this.downloading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final attachment = detail.attachmentUrl;

    return Column(
      children: [
        TimeCorrectionSummaryCard(detail: detail),
        heightBx(h: 16),
        TimeCorrectionTimesCard(detail: detail),
        if (detail.reason.isNotEmpty) ...[
          heightBx(h: 16),
          TimeCorrectionReasonCard(reason: detail.reason),
        ],
        if (attachment != null) ...[
          heightBx(h: 16),
          TimeCorrectionAttachmentCard(
            url: attachment,
            downloading: downloading,
            onView: () => _viewImage(context, attachment),
            onDownload: () => _download(context, ref),
          ),
        ],
        if (detail.steps.isNotEmpty) ...[
          heightBx(h: 16),
          TimeCorrectionApprovalWorkflow(
            steps: detail.steps,
            currentStepNo: detail.currentStepNo,
          ),
        ],
        if (detail.canCancel) ...[
          heightBx(h: 24),
          _CancelButton(
            loading: cancelling,
            onTap: () => _cancel(context, ref),
          ),
        ],
        heightBx(h: 16),
        customText(
          l10n.timeCorrectionContactNote,
          fontSize: 13,
          color: AppColors.secondaryTxt,
          alight: TextAlign.center,
          maxLine: 2,
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.timeCorrectionCancelAction,
      message: l10n.timeCorrectionCancelConfirm,
      confirmLabel: l10n.timeCorrectionCancelAction,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref
        .read(timeCorrectionDetailNotifierProvider(id).notifier)
        .cancel();
    if (!context.mounted) return;

    if (ok) {
      AppToast.success(l10n.timeCorrectionCancelled);
      context.pop(true);
    } else {
      AppToast.error(l10n.timeCorrectionCancelFailed);
    }
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(timeCorrectionDetailNotifierProvider(id).notifier)
        .saveAttachment();

    switch (outcome) {
      case AttachmentSaveOutcome.saved:
        AppToast.success(l10n.timeCorrectionAttachmentSaved);
      case AttachmentSaveOutcome.failed:
        AppToast.error(l10n.timeCorrectionAttachmentSaveFailed);
      case AttachmentSaveOutcome.dismissed:
        break;
    }
  }

  /// The evidence photo full screen, pinch-zoomable.
  void _viewImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          child: Center(
            child: Image.network(
              url,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 15, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          Expanded(
            child: customText(
              l10n.timeCorrectionDetailTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _CancelButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.danger.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 54,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.danger,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.danger,
                      ),
                      widthBx(w: 8),
                      Flexible(
                        child: customText(
                          l10n.timeCorrectionCancelAction,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final height in const [150.0, 260.0, 110.0])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: height),
          ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailed({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          heightBx(h: 8),
          customText(
            message,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 2,
          ),
          heightBx(h: 12),
          InkWell(
            onTap: onRetry,
            child: customText(
              l10n.retry,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
