import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../providers/offsite_history_notifier.dart';
import '../widgets/offsite_record_card.dart';
import '../widgets/time_correction_history_summary.dart';
import '../widgets/time_correction_image_viewer.dart';

/// "ປະຫວັດລົງເວລານອກພື້ນທີ່" — the off-site scan requests the employee has
/// filed, and the way in to filing another.
///
/// This is what the "ລົງເວລານອກພື້ນທີ່" menu tile now opens: a scan request's
/// answer arrives later (HR has to approve it unless the employee holds
/// `can_work_offsite`, §3), so the list of what is still waiting is what they
/// come back for, and [OffsiteRequestPage] sits one tap behind it. The same
/// arrangement the time-correction menu already has.
///
/// Requests and the picked tab live in [offsiteHistoryNotifierProvider].
class OffsiteHistoryPage extends ConsumerWidget {
  const OffsiteHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offsiteHistoryNotifierProvider);
    final notifier = ref.read(offsiteHistoryNotifierProvider.notifier);

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
                  onRefresh: notifier.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 32),
                    children: [
                      const _NewRequestBanner(),
                      heightBx(h: 16),
                      TimeCorrectionFilterDropdown(
                        selected: state.filter,
                        countOf: state.countOf,
                        onSelect: notifier.selectFilter,
                      ),
                      heightBx(h: 16),
                      const _RequestsList(),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          Expanded(
            child: customText(
              l10n.offsiteHistoryTitle,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              alight: TextAlign.center,
            ),
          ),
          // Balances the back button so the title stays centred.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// The picked tab's requests, or the list's loading, failed or empty state.
/// Requests already on screen stay visible while a refresh runs.
class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(offsiteHistoryNotifierProvider);
    final requests = state.requests;

    if (requests.isLoading && !requests.hasValue) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: 200),
          ),
        ),
      );
    }

    if (requests.hasError && !requests.hasValue) {
      return _Message(
        icon: Icons.error_outline,
        text: l10n.offsiteHistoryLoadFailed,
        onRetry: ref.read(offsiteHistoryNotifierProvider.notifier).refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: l10n.offsiteHistoryEmpty,
      );
    }

    return Column(
      children: [
        for (final request in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OffsiteRecordCard(
              request: request,
              onViewImage: (url) => showTimeCorrectionImage(context, url),
              onCancel: () => _cancel(context, ref, request),
              cancelling: state.cancellingIds.contains(request.id),
            ),
          ),
      ],
    );
  }

  /// Asks first — a withdrawal can't be undone, and the scan would have to be
  /// filed again — then reports what the endpoint said.
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.offsiteCancelAction,
      message: l10n.offsiteCancelConfirm,
      confirmLabel: l10n.offsiteCancelAction,
    );
    if (!confirmed || !context.mounted) return;

    final failure = await ref
        .read(offsiteHistoryNotifierProvider.notifier)
        .cancel(request);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.offsiteCancelled);
    } else {
      // `CANNOT_CANCEL` arrives localized through the datasource's token, so
      // the employee is told the request moved on rather than "it failed".
      AppToast.error(failure.localize(l10n));
    }
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gray400, size: 36),
          heightBx(h: 8),
          customText(
            text,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 2,
          ),
          if (retry != null) ...[
            heightBx(h: 12),
            InkWell(
              onTap: retry,
              child: customText(
                l10n.retry,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "ລົງເວລານອກພື້ນທີ່ໃໝ່" — opens the request form, and reloads the list when it
/// closes so a scan just filed shows up with the status the backend gave it.
class _NewRequestBanner extends ConsumerWidget {
  const _NewRequestBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () async {
            await context.push(AppRoutes.offsiteRequest);
            ref.read(offsiteHistoryNotifierProvider.notifier).refresh();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                widthBx(w: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        l10n.offsiteNewRequestTitle,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      heightBx(h: 2),
                      customText(
                        l10n.offsiteNewRequestSubtitle,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                ),
                widthBx(w: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
